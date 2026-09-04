import 'dart:convert';

class AboutInfo {
  final String schoolName;
  final String schoolTagline;
  final String schoolImageUrl;
  final String aboutSchool;
  final String founderName;
  final String founderTitle;
  final String founderImageUrl;
  final String founderJourney;
  final String developerCredit;
  final String contactEmail;
  final String contactPhone;
  final String address;
  final String websiteUrl;
  final String googleMapsUrl;
  final String instagramUrl;
  final String facebookUrl;

  const AboutInfo({
    required this.schoolName,
    required this.schoolTagline,
    required this.schoolImageUrl,
    required this.aboutSchool,
    required this.founderName,
    required this.founderTitle,
    required this.founderImageUrl,
    required this.founderJourney,
    required this.developerCredit,
    required this.contactEmail,
    required this.contactPhone,
    required this.address,
    this.websiteUrl = 'https://strawberrydaycare.co.in',
    this.googleMapsUrl = 'https://maps.app.goo.gl/efvVwz7AMGXp1EC68',
    this.instagramUrl = 'https://www.instagram.com/strawberry.preschool/',
    this.facebookUrl = 'https://www.facebook.com/daycare.strawberry',
  });

  factory AboutInfo.defaults() {
    return const AboutInfo(
      schoolName: 'Strawberry Playschool & Daycare',
      schoolTagline: 'Nurturing young minds with love, care & joyful discovery.',
      schoolImageUrl: 'assets/images/school.jpg',
      aboutSchool:
          'Welcome to Strawberry Playschool & Daycare! We are dedicated to creating a vibrant, safe, and happy learning sanctuary where each child can explore their natural curiosity, build early cognitive and social skills, and blossom with confidence.\n\nOur curriculum integrates play-based exploration, sensory activities, creative arts, and foundational early education guided by compassionate and experienced educators.',
      founderName: 'Aarti Arora',
      founderTitle: 'Founder & Director',
      founderImageUrl: 'assets/images/founder.jpg',
      founderJourney:
          'Strawberry was born out of a heartfelt dream to provide children with a warm, joyful "second home" filled with love and encouragement.\n\nBeginning with a humble classroom and a handful of eager young learners, our mission has always been deeply personal: ensuring every child feels cherished, valued, and excited to learn. Over the years, with the unwavering trust of parents, Strawberry has blossomed into a cherished early childhood institute known for holistic care, modern pedagogies, and joyful childhood memories.',
      developerCredit:
          'Designed & Developed by Harshit\nNeed app or website solutions? Contact: dev.harshitcreations@gmail.com',
      contactEmail: 'daycarestrawberry@gmail.com',
      contactPhone: '+91 99992 49495',
      address: 'BPTP Parklands, C-22, Sector 85, Faridabad, Haryana 121007',
      websiteUrl: 'https://strawberrydaycare.co.in',
      googleMapsUrl: 'https://maps.app.goo.gl/efvVwz7AMGXp1EC68',
      instagramUrl: 'https://www.instagram.com/strawberry.preschool/',
      facebookUrl: 'https://www.facebook.com/daycare.strawberry',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'school_name': schoolName,
      'school_tagline': schoolTagline,
      'school_image_url': schoolImageUrl,
      'about_school': aboutSchool,
      'founder_name': founderName,
      'founder_title': founderTitle,
      'founder_image_url': founderImageUrl,
      'founder_journey': founderJourney,
      'developer_credit': developerCredit,
      'contact_email': contactEmail,
      'contact_phone': contactPhone,
      'address': address,
      'website_url': websiteUrl,
      'google_maps_url': googleMapsUrl,
      'instagram_url': instagramUrl,
      'facebook_url': facebookUrl,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  factory AboutInfo.fromMap(Map<String, dynamic> map) {
    final def = AboutInfo.defaults();
    var email = map['contact_email']?.toString() ?? def.contactEmail;
    if (email == 'strawberryplayschool@gmail.com') {
      email = 'daycarestrawberry@gmail.com';
    }

    var devCredit = map['developer_credit']?.toString() ?? def.developerCredit;
    if (devCredit.contains('Harshit Creations')) {
      devCredit = def.developerCredit;
    }

    return AboutInfo(
      schoolName: map['school_name']?.toString() ?? def.schoolName,
      schoolTagline: map['school_tagline']?.toString() ?? def.schoolTagline,
      schoolImageUrl: map['school_image_url']?.toString() ?? def.schoolImageUrl,
      aboutSchool: map['about_school']?.toString() ?? def.aboutSchool,
      founderName: map['founder_name']?.toString() ?? def.founderName,
      founderTitle: map['founder_title']?.toString() ?? def.founderTitle,
      founderImageUrl:
          map['founder_image_url']?.toString() ?? def.founderImageUrl,
      founderJourney: map['founder_journey']?.toString() ?? def.founderJourney,
      developerCredit: devCredit,
      contactEmail: email,
      contactPhone: map['contact_phone']?.toString() ?? def.contactPhone,
      address: map['address']?.toString() ?? def.address,
      websiteUrl: map['website_url']?.toString() ?? def.websiteUrl,
      googleMapsUrl: map['google_maps_url']?.toString() ?? def.googleMapsUrl,
      instagramUrl: map['instagram_url']?.toString() ?? def.instagramUrl,
      facebookUrl: map['facebook_url']?.toString() ?? def.facebookUrl,
    );
  }

  String toJson() => jsonEncode(toMap());

  factory AboutInfo.fromJson(String source) =>
      AboutInfo.fromMap(jsonDecode(source) as Map<String, dynamic>);
}
