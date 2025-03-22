import 'package:flutter/material.dart';

class HealthChatPage extends StatefulWidget {
  @override
  _HealthChatPageState createState() => _HealthChatPageState();
}

class _HealthChatPageState extends State<HealthChatPage> {
  final List<Map<String, String>> chatHistory = [];

  final Map<String, String> predefinedQA = {
    "What are the key nutrients needed during pregnancy?":
        "Essential nutrients include iron, folic acid, calcium, and protein. These help in the baby’s growth and development.",
    "How often should a pregnant woman visit the doctor?":
        "Regular checkups should be done monthly in the first 7 months, every 2 weeks in the 8th month, and weekly in the 9th month.",
    "What foods should be avoided during pregnancy?":
        "Avoid raw or undercooked meat, unpasteurized dairy, excessive caffeine, and alcohol for a healthy pregnancy.",
    "Why are ANC checkups important?":
        "Antenatal Care (ANC) checkups monitor the mother's and baby's health, detect complications early, and ensure necessary vaccinations and supplements.",
    "What vaccinations are needed during pregnancy?":
        "TT (Tetanus Toxoid) vaccine is crucial. Some cases may also require flu or COVID-19 vaccines.",
    "How can I track my pregnancy progress?":
        "Use the pregnancy tracker in the app to log weeks, expected due date, and receive reminders for checkups and nutrition tips.",
    "What are the common signs of high-risk pregnancy?":
        "High blood pressure, severe anemia, excessive swelling, bleeding, or reduced fetal movement may indicate risks. Consult a doctor immediately.",
    "How can ASHA workers help during pregnancy?":
        "ASHA workers provide health education, track checkups, ensure proper nutrition, and assist in institutional deliveries.",
    "Why is iron supplementation important for pregnant women?":
        "Iron helps prevent anemia, supports baby’s development, and reduces the risk of premature birth.",
    "How does the app help pregnant women?":
        "The app tracks pregnancy, provides health tips, schedules ANC visits, and allows ASHA workers to send reminders.",
    "What are the benefits of institutional delivery?":
        "Institutional deliveries reduce risks of complications, provide skilled care, and ensure immediate newborn care.",
    "How can I prevent malnutrition in children?":
        "Breastfeeding, proper weaning foods, immunization, and a balanced diet help prevent malnutrition in young children.",
    "What are the symptoms of malnutrition in children?":
        "Signs include stunted growth, extreme thinness, frequent illnesses, and lack of energy.",
    "Why is exclusive breastfeeding recommended for 6 months?":
        "It provides all the necessary nutrients, strengthens immunity, and reduces infection risks.",
    "How can I monitor my child’s growth?":
        "Regular weight and height measurements, growth charts, and nutrition tracking ensure healthy development.",
    "What role do ASHA workers play in maternal health?":
        "They support pregnant women, provide health education, track checkups, and ensure institutional deliveries.",
    "What are common pregnancy complications?":
        "Complications include gestational diabetes, preeclampsia, anemia, and preterm labor. Regular ANC visits help detect them early.",
    "How can I manage morning sickness?":
        "Eat small meals, stay hydrated, avoid strong smells, and consume ginger or lemon-based drinks.",
    "Why is folic acid important during pregnancy?":
        "Folic acid prevents birth defects, supports brain development, and helps form red blood cells.",
    "What should I do if I miss an ANC checkup?":
        "Try to reschedule as soon as possible. Regular checkups are crucial for monitoring your health and the baby's development.",
  };

  void _askQuestion(String question) {
    setState(() {
      chatHistory
          .add({"question": question, "answer": predefinedQA[question]!});
    });
  }

  void _showQuestionList() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: EdgeInsets.all(10),
        height: 400, // Fixed height to avoid overflow
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: predefinedQA.keys.map((question) {
              return ListTile(
                title: Text(question),
                onTap: () {
                  Navigator.pop(context);
                  _askQuestion(question);
                },
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Health Chat")),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.all(10),
              itemCount: chatHistory.length,
              itemBuilder: (context, index) {
                final item = chatHistory[index];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Align(
                      alignment: Alignment.centerRight,
                      child: Container(
                        padding: EdgeInsets.all(10),
                        margin: EdgeInsets.symmetric(vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade100,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Text(item["question"]!,
                            style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        padding: EdgeInsets.all(10),
                        margin: EdgeInsets.symmetric(vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Text(item["answer"]!),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.all(10),
            child: ElevatedButton(
              onPressed: _showQuestionList,
              child: Text("Ask a Question"),
            ),
          ),
        ],
      ),
    );
  }
}
