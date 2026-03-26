// controllers/githubController.js
import { Contract } from "../models/index.js";
import axios from "axios";
import crypto from 'crypto';

export const connectGithubRepo = async (req, res) => {
  try {
    const { contractId, repoUrl, branch } = req.body;
    const userId = req.user.id;

    const match = repoUrl.match(/github\.com\/([^\/]+)\/([^\/]+)/);
    if (!match) {
      return res.status(400).json({ message: "Invalid GitHub URL" });
    }

    const [, owner, repo] = match;
    const cleanRepo = repo.replace('.git', '');

    const contract = await Contract.findOne({
      where: {
        id: contractId,
        FreelancerId: userId
      }
    });

    if (!contract) {
      return res.status(404).json({ message: "Contract not found" });
    }

    const webhookSecret = crypto.randomBytes(20).toString('hex');

    await contract.update({
      github_repo: `https://github.com/${owner}/${cleanRepo}`,
      github_branch: branch || 'main',
      github_webhook_secret: webhookSecret
    });

    res.json({
      message: "✅ GitHub repo connected",
      repo: `https://github.com/${owner}/${cleanRepo}`,
      branch: branch || 'main'
    });

  } catch (err) {
    console.error("Error connecting GitHub:", err);
    res.status(500).json({ message: "Server error", error: err.message });
  }
};

export const getGithubCommits = async (req, res) => {
  try {
    const { contractId } = req.params;
    const { github_token } = req.headers; 

    const contract = await Contract.findByPk(contractId);
    if (!contract || !contract.github_repo) {
      return res.status(404).json({ message: "GitHub repo not connected" });
    }

    const match = contract.github_repo.match(/github\.com\/([^\/]+)\/([^\/]+)/);
    if (!match) {
      return res.status(400).json({ message: "Invalid repo URL" });
    }

    const [, owner, repo] = match;
    const cleanRepo = repo.replace('.git', '');

    const response = await axios.get(
      `https://api.github.com/repos/${owner}/${cleanRepo}/commits`,
      {
        headers: {
          Authorization: github_token ? `token ${github_token}` : '',
          Accept: 'application/vnd.github.v3+json'
        },
        params: {
          sha: contract.github_branch,
          per_page: 10
        }
      }
    );

    const commits = response.data.map(commit => ({
      sha: commit.sha,
      message: commit.commit.message,
      author: commit.commit.author.name,
      date: commit.commit.author.date,
      url: commit.html_url
    }));

    res.json(commits);

  } catch (err) {
    console.error("Error fetching GitHub commits:", err);
    res.status(500).json({ message: "Server error", error: err.message });
  }
};

export const githubWebhook = async (req, res) => {
  try {
    const { contractId } = req.params;
    const event = req.headers['x-github-event'];
    const payload = req.body;

    const contract = await Contract.findByPk(contractId);
    if (!contract) {
      return res.status(404).json({ message: "Contract not found" });
    }

    const signature = req.headers['x-hub-signature-256'];
    // TODO: تحقق من التوقيع

    if (event === 'push') {
      const lastCommit = payload.commits[payload.commits.length - 1];
      await contract.update({
        github_last_commit: lastCommit.id
      });

      // TODO: إرسال إشعار للمستخدم
      console.log(`📦 New push to ${contract.github_repo}: ${lastCommit.message}`);
    }

    res.json({ message: "Webhook received" });

  } catch (err) {
    console.error("Error in GitHub webhook:", err);
    res.status(500).json({ message: "Server error", error: err.message });
  }
};