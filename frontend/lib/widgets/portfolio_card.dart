import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class PortfolioCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final VoidCallback? onTap;

  const PortfolioCard({
    super.key,
    required this.item,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final images = List<String>.from(item['images'] ?? []);
    final technologies = List<String>.from(item['technologies'] ?? []);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (images.isNotEmpty)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: images.length == 1
                    ? CachedNetworkImage(
                        imageUrl: images[0],
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          height: 200,
                          color: Colors.grey.shade200,
                          child: const Center(child: CircularProgressIndicator()),
                        ),
                        errorWidget: (context, url, error) => Container(
                          height: 200,
                          color: Colors.grey.shade200,
                          child: const Icon(Icons.image_not_supported, size: 50),
                        ),
                      )
                    : SizedBox(
                        height: 200,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: images.length,
                          itemBuilder: (context, index) => CachedNetworkImage(
                            imageUrl: images[index],
                            width: 200,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              width: 200,
                              color: Colors.grey.shade200,
                            ),
                          ),
                        ),
                      ),
              ),
            
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['title'] ?? 'Untitled',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  Text(
                    item['description'] ?? '',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  
                  if (technologies.isNotEmpty)
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: technologies.map((tech) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          tech,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      )).toList(),
                    ),
                  const SizedBox(height: 12),
                  
                  Row(
                    children: [
                      if (item['project_url'] != null && item['project_url'].isNotEmpty)
                        _buildLinkButton(
                          icon: Icons.open_in_browser,
                          label: 'Live Demo',
                          url: item['project_url'],
                        ),
                      if (item['github_url'] != null && item['github_url'].isNotEmpty)
                        const SizedBox(width: 12),
                      if (item['github_url'] != null && item['github_url'].isNotEmpty)
                        _buildLinkButton(
                          icon: Icons.code,
                          label: 'GitHub',
                          url: item['github_url'],
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLinkButton({required IconData icon, required String label, required String url}) {
    return GestureDetector(
      onTap: () {
        // TODO: Open URL
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: Colors.grey.shade700),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}