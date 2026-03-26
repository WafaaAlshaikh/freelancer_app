// screens/contract/my_contracts_screen.dart
import 'package:flutter/material.dart';
import '../../models/contract_model.dart';
import '../../services/api_service.dart';

class MyContractsScreen extends StatefulWidget {
  final String userRole; 
  const MyContractsScreen({super.key, required this.userRole});

  @override
  State<MyContractsScreen> createState() => _MyContractsScreenState();
}

class _MyContractsScreenState extends State<MyContractsScreen> {
  List<Contract> contracts = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchContracts();
  }


Future<void> fetchContracts() async {
  setState(() => loading = true);
  
  final data = await ApiService.getMyContracts(widget.userRole);
  
  setState(() {
    contracts = data.map((json) => Contract.fromJson(json)).toList();
    loading = false;
  });
}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.userRole == 'client' ? "My Contracts" : "Active Projects"),
        backgroundColor: Colors.white,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : contracts.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.description, size: 64, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      Text(
                        "No contracts yet",
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: contracts.length,
                  itemBuilder: (context, index) {
                    final contract = contracts[index];
                    return _buildContractCard(contract);
                  },
                ),
    );
  }


Widget _buildContractCard(Contract contract) {
  return Card(
    margin: const EdgeInsets.only(bottom: 12),
    child: ListTile(
      leading: CircleAvatar(
        backgroundColor: contract.statusColor.withOpacity(0.1),
        child: Icon(
          contract.status == 'active'
              ? Icons.check_circle
              : contract.status == 'draft'
                  ? Icons.edit
                  : Icons.access_time,
          color: contract.statusColor,
          size: 20,
        ),
      ),
      title: Text(contract.project?.title ?? 'Untitled Project'),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(contract.statusText),
          Text(
            "\$${contract.agreedAmount?.toStringAsFixed(0)}",
            style: TextStyle(color: Colors.green.shade700),
          ),
        ],
      ),
      trailing: Text(
        _getSignatureStatus(contract),
        style: TextStyle(
          fontSize: 12,
          color: contract.isSignedByBoth ? Colors.green : Colors.orange,
        ),
      ),
      onTap: () {
        Navigator.pushNamed(
          context,
          '/contract',
          arguments: {
            'contractId': contract.id,
            'userRole': widget.userRole,
          },
        );
      },
    ),
  );
}
  String _getSignatureStatus(Contract contract) {
    if (contract.isSignedByBoth) return 'Signed ✓';
    if (widget.userRole == 'client') {
      return contract.clientSignedAt != null ? 'Waiting for Freelancer' : 'Sign Now';
    } else {
      return contract.freelancerSignedAt != null ? 'Waiting for Client' : 'Sign Now';
    }
  }
}