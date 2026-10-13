import 'package:flutter/material.dart';

class OrganicManagementCard extends StatelessWidget {
  final List<String> weeds;

  const OrganicManagementCard({
    super.key,
    required this.weeds,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F8E9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFAED581)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF33691E).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.eco_rounded, color: Color(0xFF33691E), size: 22),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Zero-Chemical Bio & Organic Solutions',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1B5E20),
                      ),
                    ),
                    Text(
                      'Eco-friendly alternatives & non-toxic management',
                      style: TextStyle(fontSize: 11.5, color: Color(0xFF558B2F)),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF33691E),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'ECO MODE',
                  style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // 1. Bio-formulation
          _buildSolutionItem(
            icon: Icons.science_outlined,
            title: 'Natural Contact Bio-Herbicide',
            detail:
                'Mix 1 Litre White Vinegar (20% Acetic Acid) + 100g Rock Salt + 20ml Lemon/Neem Oil. Spray directly on weed leaves during bright sun at noon for instant foliar desiccation.',
            badge: 'Certified Organic',
          ),
          const SizedBox(height: 10),

          // 2. Mechanical Timing
          _buildSolutionItem(
            icon: Icons.handyman_outlined,
            title: 'Mechanical Inter-Cultivation',
            detail:
                'Use twin-wheel hand hoe or shallow blade harrow at 15–20 days after crop emergence. Cut weeds at crown level before seed setting to deplete root carbohydrates.',
            badge: 'Physical Control',
          ),
          const SizedBox(height: 10),

          // 3. Cultural & Mulching
          _buildSolutionItem(
            icon: Icons.layers_outlined,
            title: 'Bio-Mulching & Shading',
            detail:
                'Apply 8–10 cm dry paddy straw or sugarcane trash mulch between crop rows. Prevents sunlight penetration (zero weed germination) and conserves 35% soil moisture.',
            badge: 'Moisture Saver',
          ),
        ],
      ),
    );
  }

  Widget _buildSolutionItem({
    required IconData icon,
    required String title,
    required String detail,
    required String badge,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDCEDC8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: const Color(0xFF33691E)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Color(0xFF1B5E20),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  badge,
                  style: const TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E7D32),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            detail,
            style: const TextStyle(fontSize: 11.5, color: Colors.black87, height: 1.35),
          ),
        ],
      ),
    );
  }
}
