import 'package:flutter/material.dart';

// ==========================================================
// SIMPLE COMMUNITY DATA
// ==========================================================

class CommunityData {
  final String name;
  final String zone;
  final String description;

  CommunityData({
    required this.name,
    required this.zone,
    required this.description,
  });
}

// ==========================================================
// COMMUNITY PAGE
// ==========================================================

class CommunityPage extends StatefulWidget {
  final bool hasNewReport;

  const CommunityPage({
    super.key,
    this.hasNewReport = false,
  });

  @override
  State<CommunityPage> createState() => _CommunityPageState();
}

class _CommunityPageState extends State<CommunityPage> {
  String? selectedZone;

  // Communities created by the user
  final List<CommunityData> createdCommunities = [];

  // ==========================================================
  // GET COMMUNITIES FOR A SPECIFIC ZONE
  // ==========================================================

  List<CommunityData> communitiesForZone(String zone) {
    return createdCommunities
        .where((community) => community.zone == zone)
        .toList();
  }

  // ==========================================================
  // JOIN COMMUNITY
  // ==========================================================

  void joinCommunity() {
    if (selectedZone == null) return;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          icon: const Icon(
            Icons.groups,
            color: Color(0xFF16875B),
            size: 50,
          ),
          title: Text(
            '$selectedZone Cleanup Community',
            textAlign: TextAlign.center,
          ),
          content: Text(
            'You have joined the cleanup community for $selectedZone.\n\n'
            'You can now take part in future gotong-royong activities.',
            textAlign: TextAlign.center,
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF16875B),
                foregroundColor: Colors.white,
              ),
              child: const Text('Done'),
            ),
          ],
        );
      },
    );
  }

  // ==========================================================
  // CREATE COMMUNITY
  // ==========================================================

  void createCommunity() {
    final TextEditingController nameController =
        TextEditingController();

    final TextEditingController descriptionController =
        TextEditingController();

    String selectedCreateZone =
        selectedZone ?? 'Zone D';

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              title: const Text(
                'Create Community',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),

              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    // COMMUNITY NAME
                    const Text(
                      'Community Name',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 7),

                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        hintText: 'Example: Clean Zone D',
                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(12),
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),

                    // CHOOSE ZONE
                    const Text(
                      'Choose Zone',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 7),

                    DropdownButtonFormField<String>(
                      initialValue: selectedCreateZone,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(12),
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'Zone A',
                          child: Text('Zone A'),
                        ),
                        DropdownMenuItem(
                          value: 'Zone B',
                          child: Text('Zone B'),
                        ),
                        DropdownMenuItem(
                          value: 'Zone D',
                          child: Text('Zone D'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() {
                            selectedCreateZone = value;
                          });
                        }
                      },
                    ),

                    const SizedBox(height: 18),

                    // DESCRIPTION
                    const Text(
                      'Description',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 7),

                    TextField(
                      controller: descriptionController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText:
                            'Example: Let\'s keep our park clean together.',
                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('Cancel'),
                ),

                ElevatedButton(
                  onPressed: () {
                    final name =
                        nameController.text.trim();

                    final description =
                        descriptionController.text.trim();

                    if (name.isEmpty) {
                      return;
                    }

                    Navigator.pop(dialogContext);

                    // ADD COMMUNITY TO THE PAGE
                    setState(() {
                      createdCommunities.add(
                        CommunityData(
                          name: name,
                          zone: selectedCreateZone,
                          description:
                              description.isEmpty
                                  ? 'Local cleanup community.'
                                  : description,
                        ),
                      );

                      // Automatically select the zone
                      selectedZone =
                          selectedCreateZone;
                    });

                    ScaffoldMessenger.of(context)
                        .showSnackBar(
                      SnackBar(
                        content: Text(
                          '$name created in $selectedCreateZone!',
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        const Color(0xFF16875B),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Create'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          20,
          20,
          20,
          110,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ==================================================
            // HEADER
            // ==================================================

            const Text(
              'Community',
              style: TextStyle(
                fontSize: 27,
                fontWeight: FontWeight.bold,
                color: Color(0xFF16875B),
              ),
            ),

            const SizedBox(height: 5),

            const Text(
              'Join your neighbours and help keep the township clean.',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),

            const SizedBox(height: 25),

            // ==================================================
            // COMMUNITY BANNER
            // ==================================================

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFEAF7F1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.white,
                    child: Icon(
                      Icons.volunteer_activism,
                      color: Color(0xFF16875B),
                      size: 30,
                    ),
                  ),

                  SizedBox(width: 15),

                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Clean Together',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        SizedBox(height: 5),

                        Text(
                          'Choose an area where you want to help with gotong-royong activities.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // ==================================================
            // CHOOSE ZONE
            // ==================================================

            const Text(
              'Choose a Zone to Clean',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 5),

            const Text(
              'Select a zone and join or create a cleanup community.',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
            ),

            const SizedBox(height: 15),

            // ==================================================
            // ZONE D
            // ==================================================

            ZoneCard(
              zone: 'Zone D',
              location: 'Township Park',
              severity: 'High Severity',
              reports: widget.hasNewReport
                  ? '1 new report'
                  : 'High waste activity',
              color: Colors.red,
              recommended: true,
              selected: selectedZone == 'Zone D',
              communityCount:
                  communitiesForZone('Zone D').length,
              onTap: () {
                setState(() {
                  selectedZone = 'Zone D';
                });
              },
            ),

            // CREATED COMMUNITIES FOR ZONE D
            ...buildCommunitiesForZone('Zone D'),

            const SizedBox(height: 12),

            // ==================================================
            // ZONE B
            // ==================================================

            ZoneCard(
              zone: 'Zone B',
              location: 'Community Playground',
              severity: 'Medium Severity',
              reports: '4 reports',
              color: Colors.orange,
              selected: selectedZone == 'Zone B',
              communityCount:
                  communitiesForZone('Zone B').length,
              onTap: () {
                setState(() {
                  selectedZone = 'Zone B';
                });
              },
            ),

            // CREATED COMMUNITIES FOR ZONE B
            ...buildCommunitiesForZone('Zone B'),

            const SizedBox(height: 12),

            // ==================================================
            // ZONE A
            // ==================================================

            ZoneCard(
              zone: 'Zone A',
              location: 'Walking Track',
              severity: 'Low Severity',
              reports: '2 reports',
              color: Colors.amber,
              selected: selectedZone == 'Zone A',
              communityCount:
                  communitiesForZone('Zone A').length,
              onTap: () {
                setState(() {
                  selectedZone = 'Zone A';
                });
              },
            ),

            // CREATED COMMUNITIES FOR ZONE A
            ...buildCommunitiesForZone('Zone A'),

            const SizedBox(height: 25),

            // ==================================================
            // SELECTED ZONE
            // ==================================================

            if (selectedZone != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF7F1),
                  borderRadius:
                      BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: Color(0xFF16875B),
                    ),

                    const SizedBox(width: 10),

                    Expanded(
                      child: Text(
                        '$selectedZone selected for cleanup',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF16875B),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            if (selectedZone != null)
              const SizedBox(height: 15),

            // ==================================================
            // JOIN DEFAULT COMMUNITY
            // ==================================================

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: selectedZone == null
                    ? null
                    : joinCommunity,
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      const Color(0xFF16875B),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor:
                      Colors.grey.shade300,
                  padding:
                      const EdgeInsets.symmetric(
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(
                  Icons.group_add,
                ),
                label: Text(
                  selectedZone == null
                      ? 'Choose a Zone First'
                      : 'Join $selectedZone Community',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 25),

            const Row(
              children: [
                Expanded(child: Divider()),
                Padding(
                  padding:
                      EdgeInsets.symmetric(
                    horizontal: 12,
                  ),
                  child: Text(
                    'OR',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                ),
                Expanded(child: Divider()),
              ],
            ),

            const SizedBox(height: 20),

            // ==================================================
            // CREATE COMMUNITY
            // ==================================================

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.circular(18),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.add_circle_outline,
                    color: Color(0xFF16875B),
                    size: 35,
                  ),

                  const SizedBox(height: 10),

                  const Text(
                    'Start Your Own Community',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 5),

                  const Text(
                    'Create a local cleanup community and invite other residents to join.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),

                  const SizedBox(height: 15),

                  OutlinedButton.icon(
                    onPressed: createCommunity,
                    icon: const Icon(
                      Icons.add,
                    ),
                    label: const Text(
                      'Create Community',
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

  // ==========================================================
  // BUILD CREATED COMMUNITIES UNDER THEIR ZONE
  // ==========================================================

  List<Widget> buildCommunitiesForZone(
      String zone) {
    final communities =
        communitiesForZone(zone);

    if (communities.isEmpty) {
      return [];
    }

    return [
      const SizedBox(height: 8),

      ...communities.map(
        (community) => Padding(
          padding: const EdgeInsets.only(
            left: 18,
            bottom: 8,
          ),
          child: CreatedCommunityCard(
            community: community,
          ),
        ),
      ),
    ];
  }
}

// ==========================================================
// ZONE CARD
// ==========================================================

class ZoneCard extends StatelessWidget {
  final String zone;
  final String location;
  final String severity;
  final String reports;
  final Color color;
  final bool recommended;
  final bool selected;
  final int communityCount;
  final VoidCallback onTap;

  const ZoneCard({
    super.key,
    required this.zone,
    required this.location,
    required this.severity,
    required this.reports,
    required this.color,
    this.recommended = false,
    required this.selected,
    required this.communityCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius:
          BorderRadius.circular(18),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(17),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFFEAF7F1)
              : Colors.white,
          borderRadius:
              BorderRadius.circular(18),
          border: Border.all(
            color: selected
                ? const Color(0xFF16875B)
                : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color:
                  Colors.black.withOpacity(0.04),
              blurRadius: 8,
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.location_on,
                color: color,
              ),
            ),

            const SizedBox(width: 14),

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        zone,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),

                      if (recommended) ...[
                        const SizedBox(width: 8),

                        Container(
                          padding:
                              const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration:
                              BoxDecoration(
                            color:
                                const Color(
                                    0xFFEAF7F1),
                            borderRadius:
                                BorderRadius.circular(
                                    8),
                          ),
                          child: const Text(
                            'Recommended',
                            style: TextStyle(
                              color:
                                  Color(0xFF16875B),
                              fontSize: 9,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),

                  const SizedBox(height: 4),

                  Text(
                    location,
                    style: const TextStyle(
                      fontSize: 13,
                    ),
                  ),

                  const SizedBox(height: 6),

                  Row(
                    children: [
                      Icon(
                        Icons.circle,
                        color: color,
                        size: 10,
                      ),

                      const SizedBox(width: 5),

                      Text(
                        severity,
                        style: TextStyle(
                          color: color,
                          fontWeight:
                              FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),

                      const SizedBox(width: 8),

                      Flexible(
                        child: Text(
                          '• $reports',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),

                  // SHOW NUMBER OF CREATED COMMUNITIES
                  if (communityCount > 0) ...[
                    const SizedBox(height: 7),

                    Text(
                      '$communityCount created community',
                      style: const TextStyle(
                        color: Color(0xFF16875B),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            Icon(
              selected
                  ? Icons.check_circle
                  : Icons.chevron_right,
              color: selected
                  ? const Color(0xFF16875B)
                  : Colors.grey,
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================================
// CREATED COMMUNITY CARD
// ==========================================================

class CreatedCommunityCard extends StatelessWidget {
  final CommunityData community;

  const CreatedCommunityCard({
    super.key,
    required this.community,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FAF8),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFD8EBE0),
        ),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor:
                Color(0xFFE4F4EC),
            child: Icon(
              Icons.groups,
              color: Color(0xFF16875B),
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  community.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 3),

                const Text(
                  'Created by you',
                  style: TextStyle(
                    color: Color(0xFF16875B),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  community.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),

          const Icon(
            Icons.chevron_right,
            color: Colors.grey,
          ),
        ],
      ),
    );
  }
}