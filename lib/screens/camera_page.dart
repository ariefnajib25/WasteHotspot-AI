import 'package:flutter/material.dart';
import '../data/report_store.dart';

class CameraPage extends StatefulWidget {
  const CameraPage({super.key});

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage>
    with SingleTickerProviderStateMixin {
  bool photoCaptured = false;
  bool scanning = false;
  bool analysisCompleted = false;

  // TRUE = Public Waste demo
  // FALSE = Personal Waste demo
  bool isPublicDemo = true;

  String scanningText = 'Detecting waste...';

  late AnimationController scanController;
  late Animation<double> scanAnimation;

  int scanSession = 0;

  // ==========================================================
  // INIT
  // ==========================================================

  @override
  void initState() {
    super.initState();

    scanController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );

    scanAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: scanController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    scanController.dispose();
    super.dispose();
  }

  // ==========================================================
  // HOTSPOT INFORMATION
  // ==========================================================

  int get existingReportCount {
    return ReportStore.zoneDReportCount;
  }

  bool get duplicateDetected {
    return existingReportCount > 0;
  }

  bool get currentUserAlreadyReported {
    return ReportStore.currentUserAlreadyReportedZoneD;
  }

  int get nextReportCount {
    if (currentUserAlreadyReported) {
      return existingReportCount;
    }

    return existingReportCount + 1;
  }

  String get hotspotPriority {
    if (nextReportCount >= 3) {
      return 'URGENT';
    }

    return 'HIGH';
  }

  String get hotspotStatus {
    if (nextReportCount >= 3) {
      return 'Repeated Hotspot';
    }

    if (duplicateDetected) {
      return 'Existing Hotspot';
    }

    return 'New Hotspot';
  }

  // ==========================================================
  // LOCATION / VERIFICATION DATA
  // ==========================================================

  String get detectedLocation {
    return isPublicDemo
        ? 'Township Park, Zone D'
        : 'Registered Home Area';
  }

  String get gpsCoordinate {
    return isPublicDemo
        ? '5.6468, 100.4875'
        : '5.6459, 100.4868';
  }

  String get areaType {
    return isPublicDemo
        ? 'Public Recreational Area'
        : 'Residential Property';
  }

  String get distanceFromHome {
    return isPublicDemo ? '1.4 km' : '7 m';
  }

  String get sceneType {
    return isPublicDemo
        ? 'Outdoor Public Area'
        : 'Private Household Area';
  }

  int get publicWasteScore {
    return isPublicDemo ? 92 : 18;
  }

  String get personalWasteRisk {
    return isPublicDemo ? 'LOW' : 'HIGH';
  }

  // ==========================================================
  // CAPTURE PHOTO
  // ==========================================================

  void capturePhoto() {
    setState(() {
      photoCaptured = true;
      scanning = true;
      analysisCompleted = false;
      scanningText = 'Detecting waste...';
    });

    startAiScan();
  }

  // ==========================================================
  // AI SCANNING PROCESS
  // ==========================================================

  Future<void> startAiScan() async {
    scanSession++;

    final int currentSession = scanSession;

    scanController.repeat(
      reverse: true,
    );

    await Future.delayed(
      const Duration(milliseconds: 650),
    );

    if (!mounted ||
        currentSession != scanSession) {
      return;
    }

    setState(() {
      scanningText = 'Identifying waste type...';
    });

    await Future.delayed(
      const Duration(milliseconds: 650),
    );

    if (!mounted ||
        currentSession != scanSession) {
      return;
    }

    setState(() {
      scanningText =
          'Checking GPS & surrounding area...';
    });

    await Future.delayed(
      const Duration(milliseconds: 650),
    );

    if (!mounted ||
        currentSession != scanSession) {
      return;
    }

    setState(() {
      scanningText = 'Calculating severity...';
    });

    await Future.delayed(
      const Duration(milliseconds: 650),
    );

    if (!mounted ||
        currentSession != scanSession) {
      return;
    }

    setState(() {
      scanningText =
          'Checking duplicate hotspot...';
    });

    await Future.delayed(
      const Duration(milliseconds: 650),
    );

    if (!mounted ||
        currentSession != scanSession) {
      return;
    }

    scanController.stop();

    setState(() {
      scanning = false;
      analysisCompleted = true;
    });
  }

  // ==========================================================
  // SCAN AGAIN
  // ==========================================================

  void scanAgain() {
    scanSession++;

    scanController.stop();
    scanController.reset();

    setState(() {
      photoCaptured = false;
      scanning = false;
      analysisCompleted = false;
      scanningText = 'Detecting waste...';
    });
  }

  // ==========================================================
  // MAIN BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    if (!photoCaptured) {
      return buildCameraScreen();
    }

    return buildScanPage();
  }

  // ==========================================================
  // CAMERA SCREEN
  // ==========================================================

  Widget buildCameraScreen() {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Container(
              width: double.infinity,
              height: double.infinity,
              color: const Color(0xFF1C1C1C),
            ),

            // ==================================================
            // TOP BAR
            // ==================================================

            Positioned(
              top: 10,
              left: 10,
              right: 10,
              child: Row(
                mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),

                  const Text(
                    'Report Waste',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const Icon(
                    Icons.flash_off,
                    color: Colors.white,
                  ),
                ],
              ),
            ),

            // ==================================================
            // DEMO SELECTOR
            // ==================================================

            Positioned(
              top: 70,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: const Color(0xFF292929),
                  borderRadius:
                      BorderRadius.circular(14),
                  border: Border.all(
                    color: Colors.white12,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: buildDemoButton(
                        title: 'Public Waste',
                        icon: Icons.public,
                        selected: isPublicDemo,
                        onTap: () {
                          setState(() {
                            isPublicDemo = true;
                          });
                        },
                      ),
                    ),

                    const SizedBox(width: 5),

                    Expanded(
                      child: buildDemoButton(
                        title: 'Personal Waste',
                        icon: Icons.home_outlined,
                        selected: !isPublicDemo,
                        onTap: () {
                          setState(() {
                            isPublicDemo = false;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ==================================================
            // CAMERA VIEW
            // ==================================================

            Positioned(
              top: 135,
              left: 20,
              right: 20,
              bottom: 125,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF292929),
                  borderRadius:
                      BorderRadius.circular(22),
                ),
                child: Stack(
                  children: [
                    const Positioned(
                      top: 35,
                      left: 35,
                      child: ScanCorner(
                        top: true,
                        left: true,
                      ),
                    ),

                    const Positioned(
                      top: 35,
                      right: 35,
                      child: ScanCorner(
                        top: true,
                        left: false,
                      ),
                    ),

                    const Positioned(
                      bottom: 70,
                      left: 35,
                      child: ScanCorner(
                        top: false,
                        left: true,
                      ),
                    ),

                    const Positioned(
                      bottom: 70,
                      right: 35,
                      child: ScanCorner(
                        top: false,
                        left: false,
                      ),
                    ),

                    Positioned(
                      top: 25,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Container(
                          padding:
                              const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black38,
                            borderRadius:
                                BorderRadius.circular(
                              10,
                            ),
                          ),
                          child: Text(
                            isPublicDemo
                                ? 'PUBLIC WASTE DEMO'
                                : 'PERSONAL WASTE DEMO',
                            style: TextStyle(
                              color: isPublicDemo
                                  ? const Color(
                                      0xFF4ADE80,
                                    )
                                  : Colors.redAccent,
                              fontSize: 10,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const Positioned(
                      bottom: 25,
                      left: 0,
                      right: 0,
                      child: Text(
                        'Place rubbish inside the frame',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          fontWeight:
                              FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ==================================================
            // CAMERA BUTTON
            // ==================================================

            Positioned(
              bottom: 25,
              left: 0,
              right: 0,
              child: Center(
                child: GestureDetector(
                  onTap: capturePhoto,
                  child: Container(
                    width: 82,
                    height: 82,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color:
                            const Color(0xFF16875B),
                        width: 6,
                      ),
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      color: Color(0xFF16875B),
                      size: 34,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // PUBLIC/PERSONAL DEMO BUTTON
  // ==========================================================

  Widget buildDemoButton({
    required String title,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration:
            const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFF16875B)
              : Colors.transparent,
          borderRadius:
              BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: 17,
            ),

            const SizedBox(width: 6),

            Text(
              title,
              style: TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: selected
                    ? FontWeight.bold
                    : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // SCAN PAGE
  // ==========================================================

  Widget buildScanPage() {
    return Scaffold(
      backgroundColor:
          const Color(0xFFF5F8F6),
      appBar: AppBar(
        backgroundColor:
            const Color(0xFFF5F8F6),
        elevation: 0,
        leading: IconButton(
          onPressed: scanAgain,
          icon: const Icon(
            Icons.arrow_back,
          ),
        ),
        title: Text(
          scanning
              ? 'AI Scanning'
              : 'Waste Analysis',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          20,
          10,
          20,
          30,
        ),
        child: Column(
          children: [
            // ==================================================
            // PHOTO WITH AI SCAN ANIMATION
            // ==================================================

            buildScannedPhoto(),

            // ==================================================
            // DURING SCANNING
            // ==================================================

            if (scanning) ...[
              const SizedBox(height: 20),

              buildScanningStatus(),
            ],

            // ==================================================
            // AFTER ANALYSIS
            // ==================================================

            if (analysisCompleted) ...[
              const SizedBox(height: 18),

              buildAnalysisCompleteBanner(),

              const SizedBox(height: 18),

              buildVerificationCard(),

              const SizedBox(height: 18),

              if (isPublicDemo)
                buildPublicWasteResult()
              else
                buildPersonalWasteResult(),
            ],
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // PHOTO + SCANNER
  // ==========================================================

  Widget buildScannedPhoto() {
    return SizedBox(
      width: double.infinity,
      height: 320,
      child: Stack(
        children: [
          Positioned.fill(
            child: buildDummyWastePhoto(),
          ),

          // Dark scanning overlay
          if (scanning)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color:
                      Colors.black.withOpacity(0.12),
                  borderRadius:
                      BorderRadius.circular(22),
                ),
              ),
            ),

          // ====================================================
          // MOVING AI SCAN LINE
          // ====================================================

          if (scanning)
            Positioned.fill(
              child: ClipRRect(
                borderRadius:
                    BorderRadius.circular(22),
                child: LayoutBuilder(
                  builder:
                      (context, constraints) {
                    return AnimatedBuilder(
                      animation: scanAnimation,
                      builder: (context, child) {
                        final double top =
                            scanAnimation.value *
                                (constraints.maxHeight -
                                    16);

                        return Stack(
                          children: [
                            Positioned(
                              top: top - 22,
                              left: 10,
                              right: 10,
                              child: Container(
                                height: 48,
                                decoration:
                                    BoxDecoration(
                                  gradient:
                                      LinearGradient(
                                    begin: Alignment
                                        .topCenter,
                                    end: Alignment
                                        .bottomCenter,
                                    colors: [
                                      const Color(
                                        0xFF20C77A,
                                      ).withOpacity(
                                        0.0,
                                      ),
                                      const Color(
                                        0xFF20C77A,
                                      ).withOpacity(
                                        0.15,
                                      ),
                                      const Color(
                                        0xFF20C77A,
                                      ).withOpacity(
                                        0.0,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                            Positioned(
                              top: top,
                              left: 12,
                              right: 12,
                              child: Container(
                                height: 4,
                                decoration:
                                    BoxDecoration(
                                  color: const Color(
                                    0xFF20C77A,
                                  ),
                                  borderRadius:
                                      BorderRadius
                                          .circular(
                                    10,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          const Color(
                                        0xFF20C77A,
                                      ).withOpacity(
                                        0.75,
                                      ),
                                      blurRadius: 14,
                                      spreadRadius: 3,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
              ),
            ),

          // ====================================================
          // SCANNING LABEL
          // ====================================================

          if (scanning)
            Positioned(
              top: 17,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(
                    horizontal: 13,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color:
                        const Color(0xFF16875B),
                    borderRadius:
                        BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize:
                        MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.auto_awesome,
                        color: Colors.white,
                        size: 15,
                      ),

                      SizedBox(width: 6),

                      Text(
                        'AI SCANNING',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight:
                              FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ==========================================================
  // SCANNING STATUS
  // ==========================================================

  Widget buildScanningStatus() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const SizedBox(
            width: 34,
            height: 34,
            child:
                CircularProgressIndicator(
              strokeWidth: 3,
              color: Color(0xFF16875B),
            ),
          ),

          const SizedBox(height: 16),

          const Text(
            'AI is analysing your report',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 7),

          AnimatedSwitcher(
            duration:
                const Duration(milliseconds: 250),
            child: Text(
              scanningText,
              key: ValueKey(scanningText),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF16875B),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          const SizedBox(height: 8),

          const Text(
            'Please wait while WasteHotspot AI verifies the waste and location.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey,
              fontSize: 11,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // COMPLETE BANNER
  // ==========================================================

  Widget buildAnalysisCompleteBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF7F1),
        borderRadius:
            BorderRadius.circular(15),
      ),
      child: const Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor:
                Color(0xFF16875B),
            child: Icon(
              Icons.check,
              color: Colors.white,
              size: 19,
            ),
          ),

          SizedBox(width: 11),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'AI Analysis Complete',
                  style: TextStyle(
                    color:
                        Color(0xFF16875B),
                    fontWeight:
                        FontWeight.bold,
                    fontSize: 13,
                  ),
                ),

                SizedBox(height: 2),

                Text(
                  'Waste and location verification completed successfully.',
                  style: TextStyle(
                    color: Colors.black54,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // DUMMY PHOTO
  // ==========================================================

  Widget buildDummyWastePhoto() {
    if (isPublicDemo) {
      return buildPublicWastePhoto();
    }

    return buildPersonalWastePhoto();
  }

  // ==========================================================
  // PUBLIC PHOTO
  // ==========================================================

  Widget buildPublicWastePhoto() {
    return Container(
      width: double.infinity,
      height: 320,
      decoration: BoxDecoration(
        color: const Color(0xFFDDE4DD),
        borderRadius:
            BorderRadius.circular(22),
      ),
      child: Stack(
        children: [
          Container(
            height: 115,
            decoration:
                const BoxDecoration(
              color: Color(0xFFD6E8DF),
              borderRadius:
                  BorderRadius.vertical(
                top: Radius.circular(22),
              ),
            ),
          ),

          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 205,
            child: Container(
              decoration:
                  const BoxDecoration(
                color: Color(0xFFB5B9AD),
                borderRadius:
                    BorderRadius.vertical(
                  bottom:
                      Radius.circular(22),
                ),
              ),
            ),
          ),

          const Positioned(
            bottom: 100,
            left: 25,
            child: Icon(
              Icons.grass,
              size: 85,
              color:
                  Color(0xFF73966B),
            ),
          ),

          const Positioned(
            bottom: 100,
            right: 25,
            child: Icon(
              Icons.grass,
              size: 75,
              color:
                  Color(0xFF73966B),
            ),
          ),

          const Positioned(
            bottom: 50,
            left: 70,
            child: Icon(
              Icons.local_drink,
              size: 55,
              color: Colors.blueGrey,
            ),
          ),

          const Positioned(
            bottom: 45,
            right: 65,
            child: Icon(
              Icons.delete,
              size: 70,
              color:
                  Color(0xFF4D4D4D),
            ),
          ),

          Positioned(
            bottom: 50,
            left: 155,
            child: Transform.rotate(
              angle: 0.4,
              child: const Icon(
                Icons.fastfood,
                size: 45,
                color: Colors.orange,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // PERSONAL PHOTO
  // ==========================================================

  Widget buildPersonalWastePhoto() {
    return Container(
      width: double.infinity,
      height: 320,
      decoration: BoxDecoration(
        color: const Color(0xFFE7E0D8),
        borderRadius:
            BorderRadius.circular(22),
      ),
      child: Stack(
        children: [
          Container(
            width: double.infinity,
            height: 210,
            decoration:
                const BoxDecoration(
              color: Color(0xFFF0E8DF),
              borderRadius:
                  BorderRadius.vertical(
                top: Radius.circular(22),
              ),
            ),
          ),

          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 115,
            child: Container(
              decoration:
                  const BoxDecoration(
                color: Color(0xFFC9BBAA),
                borderRadius:
                    BorderRadius.vertical(
                  bottom:
                      Radius.circular(22),
                ),
              ),
            ),
          ),

          const Positioned(
            top: 90,
            left: 45,
            child: Icon(
              Icons.home,
              size: 90,
              color:
                  Color(0xFFB59E88),
            ),
          ),

          const Positioned(
            bottom: 40,
            right: 65,
            child: Icon(
              Icons.delete,
              size: 75,
              color:
                  Color(0xFF555555),
            ),
          ),

          const Positioned(
            bottom: 45,
            left: 80,
            child: Icon(
              Icons.fastfood,
              size: 55,
              color: Colors.orange,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // PUBLIC/PERSONAL VERIFICATION
  // ==========================================================

  Widget buildVerificationCard() {
    final Color resultColor =
        isPublicDemo
            ? const Color(0xFF16875B)
            : Colors.red;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              CircleAvatar(
                backgroundColor:
                    Color(0xFFE4F4EC),
                child: Icon(
                  Icons.location_searching,
                  color:
                      Color(0xFF16875B),
                ),
              ),

              SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Public / Personal Verification',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),

                    SizedBox(height: 2),

                    Text(
                      'Location and surroundings verified',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          VerificationRow(
            icon: Icons.place_outlined,
            title: 'Location',
            value: detectedLocation,
          ),

          const Divider(height: 28),

          VerificationRow(
            icon: Icons.gps_fixed,
            title: 'GPS',
            value: gpsCoordinate,
          ),

          const Divider(height: 28),

          VerificationRow(
            icon: Icons.map_outlined,
            title: 'Area Type',
            value: areaType,
          ),

          const Divider(height: 28),

          VerificationRow(
            icon: Icons.home_outlined,
            title: 'Distance From Home',
            value: distanceFromHome,
          ),

          const Divider(height: 28),

          VerificationRow(
            icon: Icons.image_search,
            title: 'Scene',
            value: sceneType,
          ),

          const SizedBox(height: 22),

          Row(
            mainAxisAlignment:
                MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Public Waste Score',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),

              Text(
                '$publicWasteScore%',
                style: TextStyle(
                  color: resultColor,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          ClipRRect(
            borderRadius:
                BorderRadius.circular(20),
            child:
                LinearProgressIndicator(
              value:
                  publicWasteScore / 100,
              minHeight: 9,
              backgroundColor:
                  Colors.grey.shade200,
              valueColor:
                  AlwaysStoppedAnimation<
                      Color>(
                resultColor,
              ),
            ),
          ),

          const SizedBox(height: 18),

          Container(
            width: double.infinity,
            padding:
                const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: isPublicDemo
                  ? const Color(
                      0xFFEAF7F1,
                    )
                  : const Color(
                      0xFFFFEBEE,
                    ),
              borderRadius:
                  BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Icon(
                  isPublicDemo
                      ? Icons.verified
                      : Icons.block,
                  color: resultColor,
                  size: 28,
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .start,
                    children: [
                      Text(
                        isPublicDemo
                            ? 'PUBLIC WASTE'
                            : 'LIKELY PERSONAL WASTE',
                        style: TextStyle(
                          color: resultColor,
                          fontWeight:
                              FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),

                      const SizedBox(
                        height: 3,
                      ),

                      Text(
                        isPublicDemo
                            ? 'The waste appears to be located in a public township area.'
                            : 'The waste appears to be household waste inside a private area.',
                        style:
                            const TextStyle(
                          color:
                              Colors.black54,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              const Icon(
                Icons.shield_outlined,
                color:
                    Color(0xFF16875B),
                size: 20,
              ),

              const SizedBox(width: 9),

              const Text(
                'Personal Waste Risk:',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),

              const Spacer(),

              Text(
                personalWasteRisk,
                style: TextStyle(
                  color: isPublicDemo
                      ? const Color(
                          0xFF16875B,
                        )
                      : Colors.red,
                  fontWeight:
                      FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // PUBLIC AI RESULT
  // ==========================================================

  Widget buildPublicWasteResult() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding:
              const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius:
                BorderRadius.circular(22),
          ),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  CircleAvatar(
                    backgroundColor:
                        Color(0xFFE4F4EC),
                    child: Icon(
                      Icons.auto_awesome,
                      color:
                          Color(0xFF16875B),
                    ),
                  ),

                  SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment
                              .start,
                      children: [
                        Text(
                          'AI Analysis Result',
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),

                        Text(
                          'Valid public waste report',
                          style: TextStyle(
                            color: Color(
                              0xFF16875B,
                            ),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 22),

              const AnalysisRow(
                icon: Icons.check_circle,
                title: 'Waste Detected',
                value: 'Yes',
                valueColor:
                    Color(0xFF16875B),
              ),

              const Divider(height: 28),

              const AnalysisRow(
                icon:
                    Icons.delete_outline,
                title: 'Waste Type',
                value:
                    'Plastic & Food Packaging',
              ),

              const Divider(height: 28),

              const AnalysisRow(
                icon: Icons.warning_amber,
                title: 'Severity',
                value: 'HIGH',
                valueColor: Colors.red,
              ),

              const Divider(height: 28),

              AnalysisRow(
                icon: Icons.copy,
                title: 'Duplicate Hotspot',
                value:
                    duplicateDetected
                        ? 'Yes'
                        : 'No',
                valueColor:
                    duplicateDetected
                        ? Colors.orange
                        : const Color(
                            0xFF16875B,
                          ),
              ),

              const Divider(height: 28),

              AnalysisRow(
                icon: Icons.groups_outlined,
                title:
                    'Resident Confirmations',
                value:
                    nextReportCount
                        .toString(),
                valueColor:
                    nextReportCount >= 3
                        ? Colors.red
                        : const Color(
                            0xFF16875B,
                          ),
              ),

              const Divider(height: 28),

              AnalysisRow(
                icon: Icons.priority_high,
                title: 'Hotspot Priority',
                value:
                    hotspotPriority,
                valueColor:
                    hotspotPriority ==
                            'URGENT'
                        ? const Color(0xFF8B0000)
                        : Colors.red,
              ),

              const Divider(height: 28),

              AnalysisRow(
                icon: Icons.location_on,
                title: 'Hotspot Status',
                value: hotspotStatus,
                valueColor:
                    hotspotPriority ==
                            'URGENT'
                        ? Colors.red
                        : Colors.orange,
              ),
            ],
          ),
        ),

        // ======================================================
        // EXISTING HOTSPOT
        // ======================================================

        if (duplicateDetected &&
            !currentUserAlreadyReported) ...[
          const SizedBox(height: 16),

          Container(
            width: double.infinity,
            padding:
                const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color:
                  const Color(0xFFFFF7E6),
              borderRadius:
                  BorderRadius.circular(16),
            ),
            child: Row(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.merge_type,
                  color: Colors.orange,
                  size: 27,
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .start,
                    children: [
                      const Text(
                        'Existing Hotspot Found',
                        style: TextStyle(
                          fontWeight:
                              FontWeight.bold,
                          color:
                              Colors.orange,
                        ),
                      ),

                      const SizedBox(
                        height: 4,
                      ),

                      Text(
                        'This waste matches an existing hotspot. Your confirmation will be merged into the same case. Resident confirmations will become $nextReportCount.',
                        style:
                            const TextStyle(
                          fontSize: 11,
                          color:
                              Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],

        // ======================================================
        // SAME USER BLOCKED
        // ======================================================

        if (currentUserAlreadyReported) ...[
          const SizedBox(height: 16),

          Container(
            width: double.infinity,
            padding:
                const EdgeInsets.all(17),
            decoration: BoxDecoration(
              color:
                  const Color(0xFFFFEBEE),
              borderRadius:
                  BorderRadius.circular(16),
            ),
            child: const Row(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.block,
                  color: Colors.red,
                  size: 28,
                ),

                SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .start,
                    children: [
                      Text(
                        'Already Reported',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),

                      SizedBox(height: 5),

                      Text(
                        'You have already confirmed this hotspot. The same account cannot increase the confirmation count or earn additional EcoPoints.',
                        style: TextStyle(
                          fontSize: 12,
                          color:
                              Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 18),

        // ======================================================
        // SUBMIT BUTTON
        // ======================================================

        if (!currentUserAlreadyReported)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed:
                  showSubmitConfirmation,
              style:
                  ElevatedButton.styleFrom(
                backgroundColor:
                    const Color(0xFF16875B),
                foregroundColor:
                    Colors.white,
                padding:
                    const EdgeInsets.symmetric(
                  vertical: 16,
                ),
                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(
                    14,
                  ),
                ),
              ),
              icon: Icon(
                duplicateDetected
                    ? Icons.merge
                    : Icons.send,
              ),
              label: Text(
                duplicateDetected
                    ? 'Submit & Merge Report'
                    : 'Submit Report',
                style:
                    const TextStyle(
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
            ),
          ),

        const SizedBox(height: 8),

        // ======================================================
        // SCAN AGAIN
        // ======================================================

        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: scanAgain,
            style:
                OutlinedButton.styleFrom(
              foregroundColor:
                  const Color(0xFF16875B),
              padding:
                  const EdgeInsets.symmetric(
                vertical: 15,
              ),
              side: const BorderSide(
                color:
                    Color(0xFF16875B),
              ),
              shape:
                  RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(
                  14,
                ),
              ),
            ),
            icon: const Icon(
              Icons.document_scanner_outlined,
            ),
            label: const Text(
              'Scan Again',
              style: TextStyle(
                fontWeight:
                    FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================================
  // PERSONAL WASTE RESULT
  // ==========================================================

  Widget buildPersonalWasteResult() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding:
              const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius:
                BorderRadius.circular(22),
          ),
          child: const Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor:
                        Color(0xFFFFEBEE),
                    child: Icon(
                      Icons.block,
                      color: Colors.red,
                    ),
                  ),

                  SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment
                              .start,
                      children: [
                        Text(
                          'AI Analysis Result',
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),

                        Text(
                          'Report cannot be accepted',
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              SizedBox(height: 22),

              AnalysisRow(
                icon: Icons.check_circle,
                title: 'Waste Detected',
                value: 'Yes',
              ),

              Divider(height: 28),

              AnalysisRow(
                icon:
                    Icons.delete_outline,
                title: 'Waste Type',
                value:
                    'Household Waste',
              ),

              Divider(height: 28),

              AnalysisRow(
                icon: Icons.home,
                title:
                    'Area Classification',
                value:
                    'Private Property',
                valueColor: Colors.red,
              ),

              Divider(height: 28),

              AnalysisRow(
                icon:
                    Icons.warning_amber,
                title:
                    'Personal Waste Risk',
                value: 'HIGH',
                valueColor: Colors.red,
              ),

              Divider(height: 28),

              AnalysisRow(
                icon:
                    Icons.location_off,
                title:
                    'Hotspot Creation',
                value: 'Blocked',
                valueColor: Colors.red,
              ),
            ],
          ),
        ),

        const SizedBox(height: 18),

        Container(
          width: double.infinity,
          padding:
              const EdgeInsets.all(17),
          decoration: BoxDecoration(
            color:
                const Color(0xFFFFEBEE),
            borderRadius:
                BorderRadius.circular(16),
          ),
          child: const Row(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.block,
                color: Colors.red,
                size: 28,
              ),

              SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,
                  children: [
                    Text(
                      'Public Report Blocked',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),

                    SizedBox(height: 5),

                    Text(
                      'WasteHotspot AI is designed for public waste. This scan appears to contain personal household waste inside a private area.',
                      style: TextStyle(
                        fontSize: 12,
                        color:
                            Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 15),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: scanAgain,
            style:
                ElevatedButton.styleFrom(
              backgroundColor:
                  const Color(0xFF16875B),
              foregroundColor:
                  Colors.white,
              padding:
                  const EdgeInsets.symmetric(
                vertical: 15,
              ),
              shape:
                  RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(
                  14,
                ),
              ),
            ),
            icon: const Icon(
              Icons.document_scanner_outlined,
            ),
            label: const Text(
              'Scan Again',
              style: TextStyle(
                fontWeight:
                    FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================================
  // SUBMIT REPORT
  // ==========================================================

  void showSubmitConfirmation() {
    if (currentUserAlreadyReported) {
      return;
    }

    final bool wasDuplicate =
        duplicateDetected;

    final int earnedPoints =
        ReportStore.submitZoneDReport();

    final int finalConfirmationCount =
        ReportStore.zoneDReportCount;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          icon: Icon(
            wasDuplicate
                ? Icons.merge
                : Icons.check_circle,
            color:
                const Color(0xFF16875B),
            size: 55,
          ),

          title: Text(
            wasDuplicate
                ? 'Report Merged'
                : 'Report Submitted',
            textAlign:
                TextAlign.center,
          ),

          content: Text(
            wasDuplicate
                ? 'Your confirmation has been merged into the existing hotspot.\n\nResident confirmations: $finalConfirmationCount\n\n🌱 You earned +$earnedPoints EcoPoints!'
                : 'The public waste report has been added as a new township hotspot.\n\nResident confirmations: $finalConfirmationCount\n\n🌱 You earned +$earnedPoints EcoPoints!',
            textAlign:
                TextAlign.center,
          ),

          actionsAlignment:
              MainAxisAlignment.center,

          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                );

                Navigator.pop(
                  context,
                  true,
                );
              },
              style:
                  ElevatedButton.styleFrom(
                backgroundColor:
                    const Color(
                  0xFF16875B,
                ),
                foregroundColor:
                    Colors.white,
              ),
              child: const Text(
                'View on Map',
              ),
            ),
          ],
        );
      },
    );
  }
}

// ==========================================================
// SCAN CORNER
// ==========================================================

class ScanCorner extends StatelessWidget {
  final bool top;
  final bool left;

  const ScanCorner({
    super.key,
    required this.top,
    required this.left,
  });

  @override
  Widget build(BuildContext context) {
    const green =
        Color(0xFF20C77A);

    return SizedBox(
      width: 45,
      height: 45,
      child: Stack(
        children: [
          Positioned(
            top: top ? 0 : null,
            bottom: top ? null : 0,
            left: 0,
            right: 0,
            child: Align(
              alignment: left
                  ? Alignment.centerLeft
                  : Alignment.centerRight,
              child: Container(
                width: 45,
                height: 4,
                decoration:
                    BoxDecoration(
                  color: green,
                  borderRadius:
                      BorderRadius.circular(
                    5,
                  ),
                ),
              ),
            ),
          ),

          Positioned(
            top: 0,
            bottom: 0,
            left: left ? 0 : null,
            right: left ? null : 0,
            child: Align(
              alignment: top
                  ? Alignment.topCenter
                  : Alignment.bottomCenter,
              child: Container(
                width: 4,
                height: 45,
                decoration:
                    BoxDecoration(
                  color: green,
                  borderRadius:
                      BorderRadius.circular(
                    5,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================================
// VERIFICATION ROW
// ==========================================================

class VerificationRow
    extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const VerificationRow({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          color:
              const Color(0xFF16875B),
          size: 21,
        ),

        const SizedBox(width: 11),

        Expanded(
          child: Text(
            title,
            style:
                const TextStyle(
              color: Colors.grey,
              fontSize: 12,
            ),
          ),
        ),

        Flexible(
          child: Text(
            value,
            textAlign:
                TextAlign.right,
            style:
                const TextStyle(
              fontWeight:
                  FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }
}

// ==========================================================
// ANALYSIS ROW
// ==========================================================

class AnalysisRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color? valueColor;

  const AnalysisRow({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          color:
              const Color(0xFF16875B),
          size: 22,
        ),

        const SizedBox(width: 12),

        Expanded(
          child: Text(
            title,
            style:
                const TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
        ),

        Flexible(
          child: Text(
            value,
            textAlign:
                TextAlign.right,
            style: TextStyle(
              fontSize: 14,
              fontWeight:
                  FontWeight.bold,
              color:
                  valueColor ??
                      Colors.black87,
            ),
          ),
        ),
      ],
    );
  }
}