import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/ble_providers.dart';
import '../services/ble_service.dart';
import '../widgets/app_footer.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/app_top_nav.dart';
import '../widgets/responsive/responsive_layout.dart';

class DeviceConnectivityScreen extends ConsumerStatefulWidget {
  const DeviceConnectivityScreen({super.key});

  @override
  ConsumerState<DeviceConnectivityScreen> createState() => _DeviceConnectivityScreenState();
}

class _DeviceConnectivityScreenState extends ConsumerState<DeviceConnectivityScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(ref.read(bleControllerProvider.notifier).startScan());
    });
  }

  @override
  void dispose() {
    unawaited(ref.read(bleControllerProvider.notifier).stopScan());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scanState = ref.watch(bleScanStateProvider);
    final connectionState = ref.watch(bleConnectionStateProvider);

    ref.listen(bleScanStateProvider, (previous, next) {
      if (next.errorMessage != null && next.errorMessage != previous?.errorMessage && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.errorMessage!)),
        );
      }
    });

    ref.listen(bleConnectionStateProvider, (previous, next) {
      if (next.errorMessage != null && next.errorMessage != previous?.errorMessage && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.errorMessage!)),
        );
      }
    });

    final devices = [...scanState.results];
    devices.sort((left, right) {
      final leftNamed = _deviceDisplayName(left).isNotEmpty;
      final rightNamed = _deviceDisplayName(right).isNotEmpty;
      if (leftNamed != rightNamed) {
        return leftNamed ? -1 : 1;
      }
      return right.rssi.compareTo(left.rssi);
    });

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FC),
      bottomNavigationBar: const AppBottomNav(currentIndex: 0),
      body: Column(
        children: [
          const AppTopNav(),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: ResponsiveLayout.horizontalPadding(context),
                vertical: ResponsiveLayout.verticalPadding(context),
              ),
              child: ResponsiveLayout.constrainedPage(
                context,
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                  Text(
                    'Device Connectivity',
                    style: TextStyle(
                      fontSize: ResponsiveLayout.headlineSize(context),
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF4C3E8A),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Scan for ESP32 devices, connect, and monitor connection health in real time.',
                    style: TextStyle(fontSize: 16, color: Colors.black54),
                  ),
                  const SizedBox(height: 24),
                  Wrap(
                    spacing: 24,
                    runSpacing: 24,
                    children: [
                      SizedBox(
                        width: ResponsiveLayout.isDesktop(context) ? 420 : double.infinity,
                        child: _buildStatusCard(
                          title: 'Scan Status',
                          icon: Icons.radar,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _statusChip(
                                label: scanState.isScanning ? 'Scanning' : 'Idle',
                                color: scanState.isScanning ? const Color(0xFF4C3E8A) : Colors.black54,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                scanState.summary,
                                style: const TextStyle(fontSize: 14, color: Colors.black87, height: 1.4),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                scanState.results.isEmpty ? 'No discovered devices yet.' : '${scanState.results.length} discovered device${scanState.results.length == 1 ? '' : 's'}',
                                style: const TextStyle(fontSize: 13, color: Colors.black54),
                              ),
                              const SizedBox(height: 20),
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: scanState.isScanning ? null : () => unawaited(ref.read(bleControllerProvider.notifier).startScan()),
                                      icon: const Icon(Icons.refresh),
                                      label: const Text('Scan'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF5A4D9A),
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(vertical: 14),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: scanState.isScanning ? () => unawaited(ref.read(bleControllerProvider.notifier).stopScan()) : null,
                                      icon: const Icon(Icons.stop_circle_outlined),
                                      label: const Text('Stop'),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: const Color(0xFF4C3E8A),
                                        padding: const EdgeInsets.symmetric(vertical: 14),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(
                        width: ResponsiveLayout.isDesktop(context) ? 420 : double.infinity,
                        child: _buildStatusCard(
                          title: 'Currently Connected System',
                          icon: Icons.bluetooth_connected,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _statusChip(
                                label: connectionState.phaseLabel,
                                color: _connectionColor(connectionState),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                connectionState.deviceLabel,
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                connectionState.summary,
                                style: const TextStyle(fontSize: 14, color: Colors.black87, height: 1.4),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                connectionState.mtu == null ? 'MTU will appear after a live connection is established.' : 'Negotiated MTU: ${connectionState.mtu}',
                                style: const TextStyle(fontSize: 13, color: Colors.black54),
                              ),
                              const SizedBox(height: 20),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: connectionState.device == null || connectionState.phase == BleConnectionPhase.disconnected ? null : () => unawaited(ref.read(bleControllerProvider.notifier).disconnect()),
                                  icon: const Icon(Icons.link_off),
                                  label: const Text('Disconnect'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF1B3B4A),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  if (scanState.isSimulationMode || connectionState.isSimulationMode)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3EDF7),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFD8CFEA)),
                      ),
                      child: const Text(
                        'Simulation mode is enabled. BLE operations are bypassed until the setting is turned off.',
                        style: TextStyle(color: Color(0xFF4C3E8A), fontWeight: FontWeight.w600),
                      ),
                    ),
                  if (scanState.isSimulationMode || connectionState.isSimulationMode) const SizedBox(height: 24),
                  Text(
                    'Discovered Devices',
                    style: TextStyle(
                      fontSize: ResponsiveLayout.isDesktop(context) ? 24 : 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Devices with a broadcast name are highlighted first for faster ESP32 identification.',
                    style: TextStyle(color: Colors.black54),
                  ),
                  const SizedBox(height: 16),
                  if (devices.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Text(
                        'No devices have been discovered yet. Start a scan, then bring the ESP32 into range.',
                        style: TextStyle(color: Colors.black54, height: 1.5),
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: devices.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final result = devices[index];
                        final name = _deviceDisplayName(result);
                        final isNamedDevice = name.isNotEmpty;
                        final isConnectedDevice = connectionState.device?.remoteId == result.device.remoteId && connectionState.phase == BleConnectionPhase.connected;

                        return Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final isNarrow = constraints.maxWidth <= ResponsiveLayout.mobileMaxWidth;

                              final leadingIcon = Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: isNamedDevice ? const Color(0xFFF3EDF7) : const Color(0xFFF1F1F4),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Icon(
                                  isNamedDevice ? Icons.bluetooth_searching : Icons.bluetooth_disabled,
                                  color: const Color(0xFF4C3E8A),
                                ),
                              );

                              final details = Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          isNamedDevice ? name : 'Unnamed BLE device',
                                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                                        ),
                                      ),
                                      if (isNamedDevice)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFF3EDF7),
                                            borderRadius: BorderRadius.circular(999),
                                          ),
                                          child: const Text(
                                            'Named',
                                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF4C3E8A)),
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    result.device.remoteId.str,
                                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'RSSI ${result.rssi} dBm',
                                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                                  ),
                                ],
                              );

                              final action = Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  if (isConnectedDevice)
                                    const Padding(
                                      padding: EdgeInsets.only(bottom: 8),
                                      child: Text(
                                        'Connected',
                                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1B3B4A)),
                                      ),
                                    ),
                                  ElevatedButton(
                                    onPressed: isConnectedDevice ? null : () => unawaited(ref.read(bleControllerProvider.notifier).connectToDevice(result.device)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF5A4D9A),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    ),
                                    child: Text(isConnectedDevice ? 'Connected' : 'Connect'),
                                  ),
                                ],
                              );

                              if (isNarrow) {
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        leadingIcon,
                                        const SizedBox(width: 12),
                                        Expanded(child: details),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Align(alignment: Alignment.centerRight, child: action),
                                  ],
                                );
                              }

                              return Row(
                                children: [
                                  leadingIcon,
                                  const SizedBox(width: 16),
                                  Expanded(child: details),
                                  const SizedBox(width: 12),
                                  action,
                                ],
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
          const AppFooter(),
        ],
      ),
    );
  }

  Widget _buildStatusCard({required String title, required IconData icon, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF4C3E8A)),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
            ],
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }

  Widget _statusChip({required String label, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color, letterSpacing: 1.1),
      ),
    );
  }

  Color _connectionColor(BleConnectionStateData state) {
    switch (state.phase) {
      case BleConnectionPhase.connected:
        return const Color(0xFF1B3B4A);
      case BleConnectionPhase.connecting:
      case BleConnectionPhase.reconnecting:
        return const Color(0xFFB26A00);
      case BleConnectionPhase.error:
        return const Color(0xFFC0392B);
      case BleConnectionPhase.disconnected:
        return const Color(0xFF5F6368);
    }
  }
}

String _deviceDisplayName(ScanResult result) {
  final advertisedName = result.advertisementData.advName.trim();
  if (advertisedName.isNotEmpty) {
    return advertisedName;
  }

  final platformName = result.device.platformName.trim();
  if (platformName.isNotEmpty) {
    return platformName;
  }

  return '';
}