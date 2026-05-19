import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/antigravity_service.dart';


class AgentTraceWidget extends StatelessWidget {
  final List<TraceEntry> traces;
  final Function(String)? onSimulate;
  
  const AgentTraceWidget({
    super.key,
    required this.traces,
    this.onSimulate,
  });


  @override
  Widget build(BuildContext context) {
    final service = context.watch<AntigravityService>();
    
    return Container(
      height: 310, // Increased height to comfortably fit sandbox buttons
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A2E), // Dark terminal look
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "𝐒𝐎𝐕𝐄𝐑𝐄𝐈𝐆𝐍 𝐓𝐑𝐀𝐂𝐄",
                  style: TextStyle(
                    color: Colors.cyanAccent,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                Row(
                  children: [
                    Text(
                      service.useHeuristic ? "BASELINE" : "AGENTIC",
                      style: TextStyle(
                        color: service.useHeuristic ? Colors.orangeAccent : Colors.greenAccent,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Transform.scale(
                      scale: 0.7,
                      child: Switch(
                        value: !service.useHeuristic,
                        onChanged: (val) => service.useHeuristic = !val,
                        activeThumbColor: Colors.greenAccent,
                        activeTrackColor: Colors.greenAccent.withValues(alpha: 0.3),
                        inactiveThumbColor: Colors.orangeAccent,
                        inactiveTrackColor: Colors.orangeAccent.withValues(alpha: 0.3),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Sub-header for Mode status
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              service.useHeuristic 
                ? 'MODE: SOVEREIGN BASELINE (HEURISTIC)' 
                : 'MODE: ANTIGRAVITY AGENTIC (ORCHESTRATED)',
              style: TextStyle(
                color: service.useHeuristic ? Colors.orange : const Color(0xFF00FF88),
                fontSize: 9,
                fontFamily: 'Courier',
              ),
            ),
          ),
          
          // Benchmark Stats
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatColumn("𝐀𝐆𝐄𝐍𝐓 𝐀𝐕𝐆", service.agentAvgSuccess, const Color(0xFF00FF88)),
                _buildStatColumn("𝐁𝐀𝐒𝐄𝐋𝐈𝐍𝐄 𝐀𝐕𝐆", service.baselineAvgSuccess, Colors.orangeAccent),
                _buildStatColumn("𝐒𝐄𝐒𝐒𝐈𝐎𝐍𝐒", (service.agentSessions + service.baselineSessions).toDouble(), Colors.cyanAccent, isInt: true),
              ],
            ),
          ),
          const Divider(color: Colors.white10, height: 4),

          // Judge Sandbox Controls
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "𝐉𝐔𝐃𝐆𝐄 𝐒𝐀𝐍𝐃𝐁𝐎𝐗: 𝐓𝐑𝐈𝐆𝐆𝐄𝐑 𝐎𝐑𝐂𝐇𝐄𝐒𝐓𝐑𝐀𝐓𝐈𝐎𝐍",
                  style: TextStyle(color: Colors.white54, fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                ),
                const SizedBox(height: 6),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildSandboxButton(
                        icon: Icons.emoji_events_rounded,
                        label: "Simulate Wins",
                        color: const Color(0xFF00FF88),
                        onPressed: () => onSimulate?.call('success'),
                      ),
                      const SizedBox(width: 8),
                      _buildSandboxButton(
                        icon: Icons.warning_amber_rounded,
                        label: "Simulate Fails",
                        color: Colors.orangeAccent,
                        onPressed: () => onSimulate?.call('frustration'),
                      ),
                      const SizedBox(width: 8),
                      _buildSandboxButton(
                        icon: Icons.menu_book_rounded,
                        label: "Story Quest",
                        color: Colors.cyanAccent,
                        onPressed: () => onSimulate?.call('quest'),
                      ),
                      const SizedBox(width: 8),
                      _buildSandboxButton(
                        icon: Icons.refresh_rounded,
                        label: "Eval Now",
                        color: Colors.purpleAccent,
                        onPressed: () => onSimulate?.call('evaluate'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white10, height: 4),

          // Trace log (scrollable)
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              reverse: true, // Latest at bottom
              itemCount: traces.length,
              itemBuilder: (ctx, i) {
                final trace = traces[traces.length - 1 - i];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            '[${_formatTime(trace.timestamp)}] ',
                            style: const TextStyle(
                                color: Color(0xFF888888),
                                fontSize: 10,
                                fontFamily: 'Courier'),
                          ),
                          Text(
                            trace.agent.toUpperCase(),
                            style: TextStyle(
                              color: _agentColor(trace.agent),
                              fontSize: 10,
                              fontFamily: 'Courier',
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        trace.reasoning,
                        style: const TextStyle(
                            color: Color(0xFFCCCCCC),
                            fontSize: 10,
                            fontFamily: 'Courier'),
                      ),
                      if (trace.actions.isNotEmpty)
                        Text(
                          '→ Actions: ${trace.actions.join(", ")}',
                          style: const TextStyle(
                              color: Color(0xFF00FF88),
                              fontSize: 10,
                              fontFamily: 'Courier'),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSandboxButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withValues(alpha: 0.35), width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 11),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Courier',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _agentColor(String agent) {
    switch (agent) {
      case 'Therapy Director':
        return const Color(0xFFFFD700); // Gold
      case 'Story Weaver':
        return const Color(0xFF00BFFF); // Sky blue
      case 'Progress Guardian':
        return const Color(0xFFFF69B4); // Pink
      default:
        return Colors.white;
    }
  }

  Widget _buildStatColumn(String label, double value, Color color, {bool isInt = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white38, fontSize: 8, fontWeight: FontWeight.bold)),
        Text(
          isInt ? value.toInt().toString() : "${(value * 100).toStringAsFixed(1)}%",
          style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w900, fontFamily: 'Courier'),
        ),
      ],
    );
  }

  String _formatTime(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')}';
}
