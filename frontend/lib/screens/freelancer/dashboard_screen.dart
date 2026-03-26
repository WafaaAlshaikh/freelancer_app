import 'package:flutter/material.dart';

class FreelancerDashboard extends StatelessWidget {
  const FreelancerDashboard({super.key});

  Widget statCard(String title,String value,IconData icon){

    return Expanded(

      child: Card(

        elevation:3,

        child: Padding(

          padding: const EdgeInsets.all(20),

          child: Column(

            children: [

              Icon(icon,size:35),

              const SizedBox(height:10),

              Text(
                value,
                style: const TextStyle(
                  fontSize:22,
                  fontWeight: FontWeight.bold
                ),
              ),

              const SizedBox(height:5),

              Text(title)

            ],

          ),

        ),

      ),

    );

  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        title: const Text("Freelancer Dashboard"),
      ),

      body: Padding(

        padding: const EdgeInsets.all(20),

        child: Column(

          children: [

            Row(

              children: [

                statCard("Projects","12",Icons.work),

                const SizedBox(width:10),

                statCard("Proposals","7",Icons.send),

                const SizedBox(width:10),

                statCard("Wallet","\$850",Icons.account_balance_wallet),

              ],

            ),

            const SizedBox(height:30),

            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Recent Projects",
                style: TextStyle(
                  fontSize:18,
                  fontWeight: FontWeight.bold
                ),
              ),
            ),

            const SizedBox(height:10),

            Expanded(

              child: ListView.builder(

                itemCount: 5,

                itemBuilder: (context,index){

                  return Card(

                    child: ListTile(

                      title: Text("Project ${index+1}"),

                      subtitle: const Text("Flutter mobile app"),

                      trailing: const Text("\$300"),

                    ),

                  );

                },

              ),

            )

          ],

        ),

      ),

    );
  }
}