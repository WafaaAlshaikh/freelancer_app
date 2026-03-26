// screens/contract/contract_sign_screen.dart
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../services/api_service.dart';

class ContractSignScreen extends StatefulWidget {
  final int contractId;
  final String userRole;
  
  const ContractSignScreen({
    super.key,
    required this.contractId,
    required this.userRole,
  });

  @override
  State<ContractSignScreen> createState() => _ContractSignScreenState();
}

class _ContractSignScreenState extends State<ContractSignScreen> {
  final TextEditingController codeController = TextEditingController();
  bool loading = false;
  bool codeSent = false;
  int secondsRemaining = 600; 
  int attempts = 0;

  @override
  void initState() {
    super.initState();
    requestCode();
  }

  Future<void> requestCode() async {
    setState(() => loading = true);
    
    final result = await ApiService.requestSignCode(widget.contractId);
    
    setState(() {
      loading = false;
      codeSent = true;
    });

    if (result['success'] == true) {
      Fluttertoast.showToast(msg: "✅ تم إرسال رمز التحقق");
      startTimer();
    } else {
      Fluttertoast.showToast(msg: result['message'] ?? "حدث خطأ");
    }
  }

  void startTimer() {
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted && secondsRemaining > 0) {
        setState(() => secondsRemaining--);
        startTimer();
      }
    });
  }

  Future<void> verifyAndSign() async {
    if (codeController.text.length != 6) {
      Fluttertoast.showToast(msg: "❌ الرمز يجب أن يكون 6 أرقام");
      return;
    }

    setState(() => loading = true);

    final result = await ApiService.verifyAndSign(
      widget.contractId,
      codeController.text,
    );

    setState(() => loading = false);

    if (result['success'] == true) {
      Fluttertoast.showToast(msg: "✅ تم توقيع العقد بنجاح");
      Navigator.pop(context, true);
    } else {
      setState(() => attempts++);
      Fluttertoast.showToast(msg: result['message'] ?? "❌ رمز غير صحيح");
      
      if (attempts >= 5) {
        Fluttertoast.showToast(msg: "❌ تجاوزت عدد المحاولات. أعد طلب رمز جديد");
        setState(() {
          codeSent = false;
          attempts = 0;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("توقيع العقد"),
        backgroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.security,
                size: 64,
                color: Colors.green.shade700,
              ),
            ),
            
            const SizedBox(height: 24),
            
            const Text(
              "توقيع العقد إلكترونياً",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            
            const SizedBox(height: 12),
            
            const Text(
              "تم إرسال رمز التحقق إلى بريدك الإلكتروني وجوالك",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            
            const SizedBox(height: 32),
            
            TextField(
              controller: codeController,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 24, letterSpacing: 8),
              maxLength: 6,
              decoration: InputDecoration(
                hintText: "000000",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
                counterText: "",
              ),
            ),
            
            const SizedBox(height: 16),
            
            Text(
              "صلاحية الرمز: ${(secondsRemaining / 60).floor()}:${(secondsRemaining % 60).toString().padLeft(2, '0')}",
              style: TextStyle(
                color: secondsRemaining < 60 ? Colors.red : Colors.grey,
              ),
            ),
            
            const SizedBox(height: 24),
            
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: loading ? null : verifyAndSign,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff14A800),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "تأكيد التوقيع",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
            
            const SizedBox(height: 12),
            
            TextButton(
              onPressed: secondsRemaining > 0 ? null : requestCode,
              child: Text(
                secondsRemaining > 0
                    ? "انتظر ${secondsRemaining} ثانية لإعادة الإرسال"
                    : "إعادة إرسال الرمز",
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    codeController.dispose();
    super.dispose();
  }
}