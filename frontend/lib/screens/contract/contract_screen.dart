// screens/contract/contract_screen.dart
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter_html/flutter_html.dart';
import '../../models/contract_model.dart';
import '../../services/api_service.dart';
import 'contract_sign_screen.dart';
import '../rating/add_rating_screen.dart';
import '../workspace/connect_github_screen.dart';
import '../payment/payment_screen.dart';

class ContractScreen extends StatefulWidget {
  final int contractId;
  final String userRole;

  const ContractScreen({
    super.key,
    required this.contractId,
    required this.userRole,
  });

  @override
  State<ContractScreen> createState() => _ContractScreenState();
}

class _ContractScreenState extends State<ContractScreen> {
  Contract? contract;
  bool loading = true;
  bool signing = false;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    fetchContract();
  }

  Future<void> fetchContract() async {
    setState(() => loading = true);

    try {
      final data = await ApiService.getContract(widget.contractId);
      print('📥 Contract data received: $data');
      print('📊 Milestones: ${data['milestones']}');
      setState(() {
        contract = Contract.fromJson(data);
        loading = false;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        print('✅ Milestones in contract: ${contract?.milestones}');
        print('📊 Milestones length: ${contract?.milestones?.length}');
      });
    } catch (e) {
      setState(() => loading = false);
      Fluttertoast.showToast(msg: "Error loading contract");
    }
  }

  bool get needsPayment {
    if (contract == null) return false;
    return contract!.status == 'active' &&
        contract!.escrowStatus == 'pending' &&
        widget.userRole == 'client';
  }

  bool get isEscrowFunded {
    return contract?.escrowStatus == 'funded';
  }

  Future<void> _initiatePayment() async {
    if (contract == null) return;

    setState(() => _isProcessing = true);

    try {
      final paymentIntent = await ApiService.createEscrowPaymentIntent(
        contractId: widget.contractId,
      );

      if (paymentIntent['clientSecret'] != null) {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PaymentScreen(
              contractId: widget.contractId,
              paymentIntent: paymentIntent,
            ),
          ),
        );

        if (result == true) {
          fetchContract();
        }
      } else {
        Fluttertoast.showToast(
          msg: paymentIntent['message'] ?? 'Error creating payment',
        );
      }
    } catch (e) {
      print('Error initiating payment: $e');
      Fluttertoast.showToast(msg: 'Error: $e');
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> signContract() async {
    setState(() => signing = true);

    try {
      final result = await ApiService.signContract(widget.contractId);

      if (result['contract'] != null) {
        Fluttertoast.showToast(msg: "✅ Contract signed successfully");
        fetchContract();
      } else {
        Fluttertoast.showToast(
          msg: result['message'] ?? "Error signing contract",
        );
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Error: $e");
    } finally {
      setState(() => signing = false);
    }
  }

  bool get canSign {
    if (contract == null) return false;

    print('🔍 Checking canSign for ${widget.userRole}');
    print('📊 Contract status: ${contract!.status}');
    print('👤 Client signed: ${contract!.clientSignedAt != null}');
    print('👤 Freelancer signed: ${contract!.freelancerSignedAt != null}');

    if (widget.userRole == 'client') {
      return (contract!.status == 'draft' ||
              contract!.status == 'pending_client') &&
          contract!.clientSignedAt == null;
    } else {
      return (contract!.status == 'draft' ||
              contract!.status == 'pending_freelancer') &&
          contract!.freelancerSignedAt == null;
    }
  }

  bool get isSignedByMe {
    if (contract == null) return false;

    if (widget.userRole == 'client') {
      return contract!.clientSignedAt != null;
    } else {
      return contract!.freelancerSignedAt != null;
    }
  }

  String get contractStatusText {
    if (contract == null) return '';

    switch (contract!.status) {
      case 'draft':
        return 'Awaiting Signatures';
      case 'pending_client':
        return 'Waiting for Client Signature';
      case 'pending_freelancer':
        return 'Waiting for Freelancer Signature';
      case 'active':
        return 'Contract Active';
      case 'completed':
        return 'Contract Completed';
      case 'cancelled':
        return 'Contract Cancelled';
      default:
        return contract!.status ?? 'Unknown';
    }
  }

  Color get contractStatusColor {
    switch (contract?.status) {
      case 'active':
        return Colors.green;
      case 'draft':
      case 'pending_client':
      case 'pending_freelancer':
        return Colors.orange;
      case 'completed':
        return Colors.blue;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Future<void> _showConnectGithubDialog() {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Connect GitHub'),
        content: const Text(
          'Do you want to connect a GitHub repository to this project?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      ConnectGithubScreen(contractId: widget.contractId),
                ),
              ).then((value) {
                if (value == true) {
                  fetchContract();
                }
              });
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
            child: const Text('Connect'),
          ),
        ],
      ),
    );
  }

  String _formatAmount(dynamic amount) {
    if (amount == null) return '0.00';

    double parsedAmount;
    if (amount is double) {
      parsedAmount = amount;
    } else if (amount is int) {
      parsedAmount = amount.toDouble();
    } else if (amount is String) {
      parsedAmount = double.tryParse(amount) ?? 0.0;
    } else {
      parsedAmount = 0.0;
    }

    return parsedAmount.toStringAsFixed(2);
  }

  String _formatAmountInt(dynamic amount) {
    if (amount == null) return '0';

    double parsedAmount;
    if (amount is double) {
      parsedAmount = amount;
    } else if (amount is int) {
      parsedAmount = amount.toDouble();
    } else if (amount is String) {
      parsedAmount = double.tryParse(amount) ?? 0.0;
    } else {
      parsedAmount = 0.0;
    }

    return parsedAmount.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    print('🎯 ContractScreen - userRole: ${widget.userRole}');
    print('📄 Contract status: ${contract?.status}');
    print('🔍 canSign: $canSign');
    print('👤 clientSignedAt: ${contract?.clientSignedAt}');
    print('👤 freelancerSignedAt: ${contract?.freelancerSignedAt}');

    return Scaffold(
      appBar: AppBar(
        title: const Text("Contract Agreement"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          if (contract?.status == 'active' && widget.userRole == 'freelancer')
            IconButton(
              icon: const Icon(Icons.calendar_month),
              onPressed: () {
                Navigator.pushNamed(context, '/calendar');
              },
              tooltip: 'Calendar',
            ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : contract == null
          ? const Center(child: Text("Contract not found"))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: contractStatusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: contractStatusColor),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          contract!.status == 'active'
                              ? Icons.check_circle
                              : contract!.status == 'draft'
                              ? Icons.edit
                              : Icons.access_time,
                          color: contractStatusColor,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                contractStatusText,
                                style: TextStyle(
                                  color: contractStatusColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              if (contract!.signedAt != null)
                                Text(
                                  "Signed on: ${_formatDate(contract!.signedAt)}",
                                  style: TextStyle(
                                    color: contractStatusColor.withOpacity(0.7),
                                    fontSize: 12,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Contract Amount",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          "\$${_formatAmountInt(contract!.agreedAmount)}", // ✅ استخدم الدالة الجديدة
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  if (contract!.milestones != null &&
                      contract!.milestones!.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Payment Milestones",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Found ${contract!.milestones!.length} milestones',
                          style: const TextStyle(color: Colors.blue),
                        ),

                        ...contract!.milestones!.map((milestone) {
                          return _buildMilestoneCard(
                            milestone,
                            contract!.milestones!.indexOf(milestone),
                          );
                        }).toList(),

                        const SizedBox(height: 16),
                      ],
                    )
                  else
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          'No milestones found for this contract',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ),
                    ),
                  const SizedBox(height: 20),

                  if (contract!.status == 'active' &&
                      widget.userRole == 'freelancer')
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'GitHub Integration',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),

                        if (contract!.githubRepo == null) ...[
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Column(
                              children: [
                                const Icon(
                                  Icons.link,
                                  size: 48,
                                  color: Colors.grey,
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Connect your GitHub repository',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Track your progress and show your work',
                                  style: TextStyle(color: Colors.grey.shade600),
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton.icon(
                                  onPressed: _showConnectGithubDialog,
                                  icon: const Icon(Icons.link),
                                  label: const Text('Connect Repository'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.black,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ] else ...[
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.link, color: Colors.black),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        contract!.githubRepo!,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                FutureBuilder<List<dynamic>>(
                                  future: ApiService.getGithubCommits(
                                    contract!.id!,
                                  ),
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState ==
                                        ConnectionState.waiting) {
                                      return const Center(
                                        child: CircularProgressIndicator(),
                                      );
                                    }

                                    final commits = snapshot.data ?? [];

                                    return Column(
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              'Recent Commits',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Colors.grey.shade700,
                                              ),
                                            ),
                                            Text(
                                              '${commits.length} commits',
                                              style: TextStyle(
                                                color: Colors.grey.shade600,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        ...commits
                                            .take(3)
                                            .map(
                                              (commit) => Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      vertical: 4,
                                                    ),
                                                child: Row(
                                                  children: [
                                                    const Icon(
                                                      Icons.fiber_manual_record,
                                                      size: 8,
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Text(
                                                            commit['message'],
                                                            maxLines: 1,
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                          ),
                                                          Text(
                                                            '${commit['author']} • ${_formatDateShort(DateTime.parse(commit['date']))}',
                                                            style: TextStyle(
                                                              fontSize: 10,
                                                              color: Colors
                                                                  .grey
                                                                  .shade600,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                      ],
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 20),
                      ],
                    ),

                  const Text(
                    "Contract Document",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),

                  Container(
                    height: 400,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: contract!.contractDocument != null
                        ? _buildHtmlDocument(contract!.contractDocument!)
                        : const Center(
                            child: Text("Contract document not available"),
                          ),
                  ),

                  const SizedBox(height: 24),

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Icon(
                              contract!.clientSignedAt != null
                                  ? Icons.check_circle
                                  : Icons.radio_button_unchecked,
                              color: contract!.clientSignedAt != null
                                  ? Colors.green
                                  : Colors.grey,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "Client Signature",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  if (contract!.clientSignedAt != null)
                                    Text(
                                      _formatDate(contract!.clientSignedAt),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 24),
                        Row(
                          children: [
                            Icon(
                              contract!.freelancerSignedAt != null
                                  ? Icons.check_circle
                                  : Icons.radio_button_unchecked,
                              color: contract!.freelancerSignedAt != null
                                  ? Colors.green
                                  : Colors.grey,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "Freelancer Signature",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  if (contract!.freelancerSignedAt != null)
                                    Text(
                                      _formatDate(contract!.freelancerSignedAt),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // lib/screens/contract/contract_screen.dart
                  // القسم الكامل مع التصحيح

                  // ✅ قسم الدفع - للعميل فقط
                  if (widget.userRole == 'client' &&
                      contract?.status == 'active')
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.attach_money,
                                    color: isEscrowFunded
                                        ? Colors.green
                                        : Colors.orange,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      isEscrowFunded
                                          ? '✅ Escrow Funded'
                                          : '💰 Payment Required',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: isEscrowFunded
                                            ? Colors.green
                                            : Colors.orange,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                isEscrowFunded
                                    ? 'The payment is secured in escrow. Milestone payments will be released upon approval.'
                                    : 'To activate this contract and start working, please deposit the contract amount into escrow.',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade600,
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 16),
                              if (!isEscrowFunded)
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: _isProcessing
                                        ? null
                                        : _initiatePayment,
                                    icon: _isProcessing
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : const Icon(Icons.lock_clock),
                                    label: Text(
                                      _isProcessing
                                          ? 'Processing...'
                                          : 'Pay \$${_formatAmount(contract?.agreedAmount)}',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xff14A800),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 14,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ),
                              if (isEscrowFunded)
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.green.shade200,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.check_circle,
                                        color: Colors.green.shade700,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          'Payment secured: \$${_formatAmount(contract?.agreedAmount)} in escrow',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Colors.green.shade700,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),

                  const SizedBox(height: 24),

                  if (contract!.status == 'completed')
                    FutureBuilder<Map<String, dynamic>>(
                      future: ApiService.checkCanRate(widget.contractId),
                      builder: (context, snapshot) {
                        if (snapshot.hasData &&
                            snapshot.data!['canRate'] == true) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 16),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.amber.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.amber.shade200,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.rate_review,
                                        color: Colors.amber.shade700,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Project completed! Rate your experience',
                                          style: TextStyle(
                                            color: Colors.amber.shade800,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: () async {
                                        final result = await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => AddRatingScreen(
                                              contractId: widget.contractId,
                                              projectTitle:
                                                  contract!.project?.title ??
                                                  'Project',
                                              otherPartyName:
                                                  widget.userRole == 'client'
                                                  ? contract!
                                                            .freelancer
                                                            ?.name ??
                                                        'Freelancer'
                                                  : contract!.client?.name ??
                                                        'Client',
                                              role: widget.userRole,
                                            ),
                                          ),
                                        );

                                        if (result == true) {
                                          fetchContract();
                                        }
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.amber,
                                        foregroundColor: Colors.white,
                                      ),
                                      child: const Text('Write a Review'),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),

                  if (canSign)
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: signing ? null : _navigateToSignScreen,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xff14A800),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: signing
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : Text(
                                isSignedByMe
                                    ? "Waiting for Other Party"
                                    : "Sign Contract",
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),

                  if (contract!.status == 'active')
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Center(
                        child: Text(
                          "Contract is active. You can now start working!",
                          style: TextStyle(
                            color: Colors.green.shade700,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildHtmlDocument(String htmlContent) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Html(
        data: htmlContent,
        style: {
          "body": Style(
            fontSize: FontSize(14.0),
            lineHeight: LineHeight(1.6),
            color: Colors.black87,
          ),
          "h1": Style(
            fontSize: FontSize(24),
            color: const Color(0xff14A800),
            textAlign: TextAlign.center,
            margin: Margins.only(bottom: 20),
            fontWeight: FontWeight.bold,
          ),
          "h2": Style(
            fontSize: FontSize(18),
            fontWeight: FontWeight.bold,
            margin: Margins.only(top: 16, bottom: 8),
          ),
          "p": Style(margin: Margins.only(bottom: 8)),
          ".signature": Style(
            margin: Margins.only(top: 32),
            fontStyle: FontStyle.italic,
            fontSize: FontSize(16),
          ),
          ".terms": Style(
            backgroundColor: Colors.grey.shade50,
            padding: HtmlPaddings.all(16),
            margin: Margins.only(top: 8, bottom: 8),
          ),
          "strong": Style(fontWeight: FontWeight.bold),
        },
      ),
    );
  }

  Widget _buildMilestoneCard(Map<String, dynamic> milestone, int index) {
    double getAmount(dynamic value) {
      if (value == null) return 0.0;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    final isCompleted = milestone['status'] == 'completed';
    final isApproved = milestone['status'] == 'approved';
    final isPending =
        milestone['status'] == 'pending' ||
        milestone['status'] == 'in_progress';
    final progress = getAmount(milestone['progress']);
    final amount = getAmount(milestone['amount']);

    Color statusColor;
    IconData statusIcon;
    String statusText;

    if (isApproved) {
      statusColor = Colors.green;
      statusIcon = Icons.check_circle;
      statusText = 'Paid ✓';
    } else if (isCompleted) {
      statusColor = Colors.orange;
      statusIcon = Icons.pending;
      statusText = 'Completed - Awaiting Approval';
    } else if (isPending) {
      statusColor = Colors.blue;
      statusIcon = Icons.radio_button_unchecked;
      statusText = 'In Progress';
    } else {
      statusColor = Colors.grey;
      statusIcon = Icons.block;
      statusText = 'Not Started';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(statusIcon, color: statusColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        milestone['title'] ?? 'Milestone ${index + 1}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        statusText,
                        style: TextStyle(
                          fontSize: 12,
                          color: statusColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '\$${amount.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade700,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            if (milestone['description'] != null &&
                milestone['description'].toString().isNotEmpty)
              Text(
                milestone['description'],
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade700,
                  height: 1.4,
                ),
              ),

            const SizedBox(height: 12),

            if (milestone['due_date'] != null)
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 14,
                    color: Colors.grey.shade500,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Due: ${_formatDateShort(DateTime.parse(milestone['due_date']))}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),

            const SizedBox(height: 12),

            if (!isApproved)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Progress',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      Text(
                        '${progress.toInt()}%',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress / 100,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                      minHeight: 6,
                    ),
                  ),
                ],
              ),

            if (widget.userRole == 'freelancer' && !isCompleted && !isApproved)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isProcessing
                            ? null
                            : () => _completeMilestone(index),
                        icon: const Icon(Icons.check_circle, size: 18),
                        label: Text(
                          progress >= 100
                              ? 'Mark as Completed'
                              : 'Update Progress',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xff14A800),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            if (widget.userRole == 'client' && isCompleted && !isApproved)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isProcessing
                            ? null
                            : () => _approveMilestone(index),
                        icon: const Icon(Icons.attach_money, size: 18),
                        label: Text(
                          'Approve & Release \$${amount.toStringAsFixed(0)}',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _requestRevision(index),
                        icon: const Icon(Icons.edit, size: 18),
                        label: const Text("Request Changes"),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            if (isApproved)
              Container(
                margin: const EdgeInsets.only(top: 12),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: Colors.green.shade700,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Payment released on ${_formatDateShort(milestone['approved_at'] != null ? DateTime.parse(milestone['approved_at']) : DateTime.now())}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green.shade700,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _completeMilestone(int index) async {
    setState(() => _isProcessing = true);

    try {
      final result = await ApiService.updateMilestoneProgress(
        contractId: widget.contractId,
        milestoneIndex: index,
        progress: 100,
        status: 'completed',
      );

      if (result['success'] == true || result['message'] != null) {
        Fluttertoast.showToast(
          msg: result['message'] ?? '✅ Milestone marked as completed',
        );
        fetchContract();
      } else {
        Fluttertoast.showToast(
          msg: result['message'] ?? 'Error completing milestone',
        );
      }
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error: $e');
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _approveMilestone(int index) async {
    final milestone = contract!.milestones![index];
    double getAmount(dynamic value) {
      if (value == null) return 0.0;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    final amount = getAmount(milestone['amount']);

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Approve Milestone'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to approve "${milestone['title']}"?'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.attach_money, color: Colors.green),
                  const SizedBox(width: 8),
                  Text(
                    '\$${amount.toStringAsFixed(2)} will be released to the freelancer',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'This action cannot be undone.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xff14A800),
            ),
            child: const Text('Approve & Release'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isProcessing = true);

    try {
      final result = await ApiService.approveMilestone(
        contractId: widget.contractId,
        milestoneIndex: index,
      );

      if (result['success'] == true) {
        Fluttertoast.showToast(
          msg: result['message'] ?? '✅ Milestone approved and payment released',
        );
        fetchContract();
      } else {
        Fluttertoast.showToast(
          msg: result['message'] ?? 'Error approving milestone',
        );
      }
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error: $e');
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _requestRevision(int index) async {
    final controller = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Request Changes'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Please explain what needs to be changed:'),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Describe the changes needed...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Send Request'),
          ),
        ],
      ),
    );

    if (confirmed == true && controller.text.isNotEmpty) {
      // TODO: إرسال طلب التعديل
      Fluttertoast.showToast(msg: 'Revision request sent to freelancer');
    }
  }

  Future<void> _navigateToSignScreen() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ContractSignScreen(
          contractId: widget.contractId,
          userRole: widget.userRole,
        ),
      ),
    );

    if (result == true) {
      fetchContract();
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Not signed';
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatDateShort(DateTime date) {
    return '${date.day}/${date.month}';
  }
}
