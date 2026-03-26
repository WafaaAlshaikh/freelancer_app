// lib/screens/client/negotiation_screen.dart
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../services/api_service.dart';
import '../../models/proposal_model.dart';
import '../../widgets/milestone_editor.dart';

class NegotiationScreen extends StatefulWidget {
  final Proposal proposal;
  const NegotiationScreen({super.key, required this.proposal});

  @override
  State<NegotiationScreen> createState() => _NegotiationScreenState();
}

class _NegotiationScreenState extends State<NegotiationScreen> {
  double? agreedPrice;
  List<Map<String, dynamic>> milestones = [];
  bool loading = false;

  @override
  void initState() {
    super.initState();
    agreedPrice = widget.proposal.price;
    milestones = List.from(widget.proposal.milestones ?? []);
  }

  Future<void> _updateNegotiation() async {
    setState(() => loading = true);

    final result = await ApiService.updateNegotiation(
      proposalId: widget.proposal.id!,
      price: agreedPrice,
      milestones: milestones,
    );

    setState(() => loading = false);

    if (result['proposal'] != null) {
      Fluttertoast.showToast(msg: 'Negotiation updated');
    } else {
      Fluttertoast.showToast(msg: result['message'] ?? 'Error');
    }
  }

  Future<void> _acceptProposal() async {
    setState(() => loading = true);

    final result = await ApiService.acceptProposal(
      proposalId: widget.proposal.id!,
      agreedPrice: agreedPrice,
      agreedMilestones: milestones,
    );

    setState(() => loading = false);

    if (result['contract'] != null) {
      Fluttertoast.showToast(msg: '✅ Proposal accepted!');
      Navigator.pushReplacementNamed(
        context,
        '/payment',
        arguments: {
          'contractId': result['contract']['id'],
          'paymentIntent': result['paymentIntent'],
        },
      );
    } else {
      Fluttertoast.showToast(msg: result['message'] ?? 'Error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Negotiate Contract'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundImage: widget.proposal.freelancer?.avatar != null
                      ? NetworkImage(widget.proposal.freelancer!.avatar!)
                      : null,
                  child: widget.proposal.freelancer?.avatar == null
                      ? Text(widget.proposal.freelancer?.name?[0] ?? 'F')
                      : null,
                ),
                title: Text(widget.proposal.freelancer?.name ?? 'Freelancer'),
                subtitle: Text(widget.proposal.proposalText ?? ''),
              ),
            ),
            const SizedBox(height: 16),

            const Text('Agreed Price', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextFormField(
              initialValue: agreedPrice?.toStringAsFixed(0),
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                prefixText: '\$ ',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                agreedPrice = double.tryParse(value);
              },
            ),
            const SizedBox(height: 16),

            const Text('Milestones', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            MilestoneEditor(
              milestones: milestones,
              onChanged: (newMilestones) {
                setState(() {
                  milestones = newMilestones;
                });
              },
            ),
            const SizedBox(height: 24),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: loading ? null : _updateNegotiation,
                    child: const Text('Update'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: loading ? null : _acceptProposal,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xff14A800),
                    ),
                    child: const Text('Accept & Create Contract'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}