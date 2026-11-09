class ChatbotService {
  static const String milkBankIntro =
      "Hello! I am MilkLink AI Assistant for Pasig City Human Milk Bank. "
      "I am here to guide you through donor registration, medical screening, "
      "safe milk storage, and requesting human milk.";

  static String getDonationSteps() {
    return "Thank you for your interest in donating breast milk to Pasig City Human Milk Bank!\n\n"
        "Here's how you can start:\n\n"
        "1. Complete the donor registration form (workflow).\n"
        "2. Answer the required medical screening questionnaire.\n"
        "3. Submit the required laboratory documents (CBC, HIV, HBsAg, Anti-HCV).\n"
        "4. Wait for screening and verification by authorized healthcare personnel.\n"
        "5. Once approved, coordinate your donation or milk pickup with the milk bank.\n"
        "6. The milk bank will record, inspect, process, pasteurize, and store your donated milk.\n\n"
        "If you are already a registered donor, please coordinate your next donation with milk bank staff. "
        "You do not need to register again!";
  }

  static String getStorageGuidance() {
    return "Safe Breast Milk Storage Guidelines (Pasig City Human Milk Bank):\n\n"
        "• Room Temperature (up to 25°C): Up to 4 hours\n"
        "• Insulated Cooler with Ice Packs: Up to 24 hours\n"
        "• Refrigerator (4°C): Up to 4 days\n"
        "• Freezer Compartment inside Refrigerator (-15°C): Up to 2 weeks\n"
        "• Deep Freezer (-20°C): 3 to 6 months\n\n"
        "Always label your milk bags with donor name, expression date, and time!";
  }

  static String getMilkRequestGuidance() {
    return "How to request human milk from Pasig City Human Milk Bank:\n\n"
        "1. Go to the Milk Request section in your dashboard.\n"
        "2. Fill in the recipient's information and physician's prescription.\n"
        "3. Indicate required volume in mL and duration.\n"
        "4. Submit for review by authorized healthcare staff.\n\n"
        "Note: Registered donors do not receive automatic approval; all requests undergo clinical evaluation.";
  }

  static Map<String, dynamic> generateResponse(String input) {
    final lower = input.toLowerCase().trim();

    if (lower.contains('how') && (lower.contains('donate') || lower.contains('start'))) {
      return {
        'text': getDonationSteps(),
        'action': 'REGISTER_DONOR',
        'actionLabel': 'Open Donor Registration',
      };
    }

    if (lower.contains('returning') || lower.contains('again') || lower.contains('repeat')) {
      return {
        'text': "Returning donors do NOT need to register or log in again to donate! "
            "You can present your Donor ID or QR code at any Pasig City milk letting event "
            "or collection outpost, and staff will log your donation directly.",
        'action': 'SEARCH_DONOR',
        'actionLabel': 'Lookup My Donor ID',
      };
    }

    if (lower.contains('store') || lower.contains('storage') || lower.contains('handle') || lower.contains('freezer')) {
      return {
        'text': getStorageGuidance(),
        'action': null,
        'actionLabel': null,
      };
    }

    if (lower.contains('request') || lower.contains('need milk') || lower.contains('recipient')) {
      return {
        'text': getMilkRequestGuidance(),
        'action': 'REQUEST_MILK',
        'actionLabel': 'Go to Milk Request Form',
      };
    }

    if (lower.contains('lab') || lower.contains('cbc') || lower.contains('hiv') || lower.contains('screening')) {
      return {
        'text': "The standard donor screening requires:\n\n"
            "• Complete Blood Count (CBC)\n"
            "• HIV Screening\n"
            "• Hepatitis B Surface Antigen (HBsAg)\n"
            "• Hepatitis C (Anti-HCV)\n\n"
            "You can upload your laboratory documents directly for authorized healthcare staff review.",
        'action': 'UPLOAD_LABS',
        'actionLabel': 'View Screening / Uploads',
      };
    }

    if (lower.contains('pickup') || lower.contains('collect') || lower.contains('home')) {
      return {
        'text': "MilkLink supports milk pickup scheduling across 5 Pasig City collection outposts! "
            "Eligible donors can choose their preferred date and morning/afternoon time slot.",
        'action': 'SCHEDULE_PICKUP',
        'actionLabel': 'Schedule Milk Pickup',
      };
    }

    return {
      'text': "I can assist you with:\n"
          "• How to donate breast milk\n"
          "• Returning donor identification\n"
          "• Safe milk storage guidance\n"
          "• Required laboratory tests\n"
          "• Milk pickup scheduling\n"
          "• Requesting pasteurized human milk\n\n"
          "How can I help you today?",
      'action': null,
      'actionLabel': null,
    };
  }
}
