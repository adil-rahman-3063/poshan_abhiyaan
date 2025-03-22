import 'package:flutter/material.dart';

class AboutPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('About the Scheme')),
      body: ListView(
        children: [
          buildExpansionTile(
            "Benefits for Pregnant Women & Lactating Mothers",
            [
              buildSubTile(
                "Financial Assistance",
                [
                  "✅ Pradhan Mantri Matru Vandana Yojana (PMMVY)",
                  "₹5,000 in three installments for the first pregnancy.",
                  "₹1,000 on early pregnancy registration.",
                  "₹2,000 after one ANC checkup (6 months).",
                  "₹2,000 after childbirth and first immunization.",
                  "✅ Janani Suraksha Yojana (JSY)",
                  "₹1,000 for institutional delivery (₹1,400 for rural areas).",
                  "Free hospital delivery, medicines, food, and transport."
                ],
              ),
              buildSubTile(
                "Nutritional Support",
                [
                  "✅ Take-Home Ration (THR) & Hot Cooked Meals",
                  "Iron & Folic Acid (IFA) supplements for anemia prevention.",
                  "Free nutritious meals at Anganwadi Centers.",
                  "Fortified rice, wheat, and pulses for improved nutrition."
                ],
              ),
              buildSubTile(
                "Health Checkups & Immunization",
                [
                  "✅ Antenatal & Postnatal Care (ANC & PNC)",
                  "4 mandatory ANC checkups with BP, weight, and hemoglobin tests.",
                  "Two Tetanus Toxoid (TT) injections for safety.",
                  "✅ Home-Based Newborn Care (HBNC)",
                  "ASHA workers visit homes for health monitoring.",
                  "✅ Free Medicines & Supplements",
                  "IFA tablets (Iron & Folic Acid) from the 3rd month.",
                  "Calcium supplements from the 4th month."
                ],
              ),
              buildSubTile(
                "Breastfeeding & Awareness Campaigns",
                [
                  "✅ Mothers’ Meetings & POSHAN Maah",
                  "Awareness on exclusive breastfeeding for 6 months.",
                  "✅ Mother’s Absolute Affection (MAA) Program",
                  "Promotes breastfeeding & kangaroo mother care.",
                  "✅ Sanitary Napkins under Menstrual Hygiene Scheme",
                  "ASHA workers distribute affordable sanitary napkins."
                ],
              ),
            ],
          ),
          buildExpansionTile(
            "Benefits for Children Under 15 Years",
            [
              buildSubTile(
                "Nutrition & Growth Monitoring",
                [
                  "✅ Supplementary Nutrition at Anganwadi Centers",
                  "Take-Home Ration (THR) for children (0-6 years).",
                  "Hot cooked meals for children 3-6 years.",
                  "✅ Rashtriya Bal Swasthya Karyakram (RBSK)",
                  "Free health checkups for children up to 18 years.",
                  "Free treatment for heart defects, anemia, malnutrition, TB, vision problems."
                ],
              ),
              buildSubTile(
                "Immunization & Free Healthcare",
                [
                  "✅ Universal Immunization Programme (UIP)",
                  "Free vaccines for polio, measles, tetanus, hepatitis B.",
                  "✅ Deworming & Vitamin A Supplementation",
                  "Twice-a-year deworming tablets for children 1-19 years.",
                  "✅ Free Treatment for Severe Malnutrition",
                  "Children with Severe Acute Malnutrition (SAM) get free treatment at NRCs."
                ],
              ),
              buildSubTile(
                "Adolescent Girls (11-15 years)",
                [
                  "✅ Scheme for Adolescent Girls (SAG)",
                  "Take-Home Ration & iron supplements for girls 11-14 years.",
                  "✅ Kishori Shakti Yojana (KSY)",
                  "Vocational training, self-defense training, and hygiene education.",
                  "✅ Menstrual Hygiene Scheme (MHS)",
                  "ASHA workers distribute sanitary napkins at ₹6 per pack in rural areas.",
                  "✅ School Health & Wellness Program",
                  "Sessions on nutrition, mental health, fitness, and substance abuse prevention."
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget buildExpansionTile(String title, List<Widget> children) {
    return Card(
      elevation: 3,
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      child: ExpansionTile(
        title: Text(
          title,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        children: children,
      ),
    );
  }

  Widget buildSubTile(String subTitle, List<String> content) {
    return ExpansionTile(
      title: Text(
        subTitle,
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
      children: content.map((text) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
          child: Text(text, style: TextStyle(fontSize: 14)),
        );
      }).toList(),
    );
  }
}
