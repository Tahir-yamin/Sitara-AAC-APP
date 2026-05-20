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
      height: 400, // Extended to fit new flow diagram section
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A2E),
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
                _buildStatColumn("𝐀𝐆𝐄𝐍𝐓 𝐀𝐕𝐆", service.agentAvgSuccess, const Color(0xFF00FF88),
                    noData: service.agentSessions == 0),
                _buildStatColumn("𝐁𝐀𝐒𝐄𝐋𝐈𝐍𝐄 𝐀𝐕𝐆", service.baselineAvgSuccess, Colors.orangeAccent,
                    noData: service.baselineSessions == 0),
                _buildStatColumn("𝐒𝐄𝐒𝐒𝐈𝐎𝐍𝐒", (service.agentSessions + service.baselineSessions).toDouble(), Colors.cyanAccent, isInt: true),
              ],
            ),
          ),
          const Divider(color: Colors.white10, height: 4),

          // ── Animated Flow Diagram ──────────────────────────────────
          _AgentFlowDiagram(traces: traces),
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
              reverse: true,
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
    if (agent.contains('Therapy Director')) return const Color(0xFFFFD700);
    if (agent.contains('Story Weaver'))     return const Color(0xFF00BFFF);
    if (agent.contains('Progress Guardian')) return const Color(0xFFFF69B4);
    if (agent.contains('Sovereign'))        return Colors.orangeAccent;
    if (agent.contains('Heuristic'))        return Colors.orange;
    return Colors.white70;
  }

  Widget _buildStatColumn(String label, double value, Color color,
      {bool isInt = false, bool noData = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white38, fontSize: 8, fontWeight: FontWeight.bold)),
        Text(
          noData
              ? 'N/A'
              : isInt
                  ? value.toInt().toString()
                  : "${(value * 100).toStringAsFixed(1)}%",
          style: TextStyle(
            color: noData ? Colors.white24 : color,
            fontSize: 12,
            fontWeight: FontWeight.w900,
            fontFamily: 'Courier',
          ),
        ),
      ],
    );
  }

  String _formatTime(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')}';
}


// ── Animated Flow Diagram ─────────────────────────────────────────
// Shows the live agent orchestration flow with pulsing active nodes.

class _AgentFlowDiagram extends StatefulWidget {
  final List<TraceEntry> traces;
  const _AgentFlowDiagram({required this.traces});

  @override
  State<_AgentFlowDiagram> createState() => _AgentFlowDiagramState();
}

class _AgentFlowDiagramState extends State<_AgentFlowDiagram>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulse;
  late Animation<double> _glow;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
        duration: const Duration(milliseconds: 850), vsync: this)
      ..repeat(reverse: true);
    _glow = CurvedAnimation(parent: _pulse, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  // Determine which node is active from the latest trace entry
  _ActiveNode _activeNode() {
    if (widget.traces.isEmpty) return _ActiveNode.none;
    final agent = widget.traces.last.agent;
    final reasoning = widget.traces.last.reasoning;
    if (agent.contains('Story Weaver')) return _ActiveNode.storyWeaver;
    if (agent.contains('Progress Guardian')) return _ActiveNode.guardian;
    if (agent.contains('Therapy Director')) return _ActiveNode.therapyDirector;
    // Fallback tiers still mean therapy director ran (or failed)
    if (agent.contains('Sovereign') || agent.contains('Heuristic') ||
        reasoning.contains('BASELINE')) {
      return _ActiveNode.therapyDirector;
    }
    return _ActiveNode.none;
  }

  String _activeTier() {
    if (widget.traces.isEmpty) return 'T4';
    final r = widget.traces.last.reasoning;
    final a = widget.traces.last.agent;
    if (a.contains('Therapy Director') && !r.contains('BASELINE')) return 'T1';
    if (r.contains('T2') || r.contains('OpenRouter')) return 'T2';
    if (r.contains('T3') || r.contains('Bedrock'))    return 'T3';
    return 'T4';
  }

  @override
  Widget build(BuildContext context) {
    final active = _activeNode();
    final tier   = _activeTier();

    return AnimatedBuilder(
      animation: _glow,
      builder: (ctx, _) {
        return SizedBox(
          height: 78,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Flutter app node (always dim — it's the sender)
                _flowNode('📱', 'Flutter\nApp', Colors.white54, false),

                _flowArrow('30s\nPOST'),

                // Therapy Director — lights up on most events
                _flowNode('🧠', 'Therapy\nDirector', const Color(0xFFFFD700),
                    active == _ActiveNode.therapyDirector),

                _flowArrow('A2A'),

                // Story Weaver — lights up only on quest/A2A events
                _flowNode('📖', 'Story\nWeaver', const Color(0xFF00BFFF),
                    active == _ActiveNode.storyWeaver),

                _flowArrow('→'),

                // Active Tier badge
                _tierBadge(tier),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _flowNode(String emoji, String label, Color color, bool active) {
    final brightness = active ? _glow.value : 0.0;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: active ? 0.18 + 0.12 * brightness : 0.06),
            border: Border.all(
              color: color.withValues(alpha: active ? 0.5 + 0.5 * brightness : 0.25),
              width: active ? 1.8 : 1.0,
            ),
            boxShadow: active
                ? [BoxShadow(
                    color: color.withValues(alpha: 0.35 * brightness),
                    blurRadius: 10,
                    spreadRadius: 2)]
                : [],
          ),
          child: Center(child: Text(emoji, style: const TextStyle(fontSize: 15))),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: color.withValues(alpha: active ? 0.9 : 0.35),
            fontSize: 7,
            fontFamily: 'Courier',
            fontWeight: active ? FontWeight.bold : FontWeight.normal,
            height: 1.2,
          ),
        ),
      ],
    );
  }

  Widget _flowArrow(String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('→', style: TextStyle(color: Colors.white24, fontSize: 13)),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white24, fontSize: 6, fontFamily: 'Courier', height: 1.1),
        ),
      ],
    );
  }

  Widget _tierBadge(String tier) {
    const colors = {
      'T1': Colors.cyanAccent,
      'T2': Colors.yellowAccent,
      'T3': Colors.purpleAccent,
      'T4': Colors.orangeAccent,
    };
    const labels = {
      'T1': 'T1\nGemini',
      'T2': 'T2\nBedrock',
      'T3': 'T3\nOpenRouter',
      'T4': 'T4\nHeuristic',
    };
    final color = (colors[tier] ?? Colors.orangeAccent) as Color;
    final label = labels[tier] ?? 'T4\nHeuristic';
    final brightness = _glow.value;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(5),
            color: color.withValues(alpha: 0.12 + 0.08 * brightness),
            border: Border.all(
              color: color.withValues(alpha: 0.45 + 0.35 * brightness),
              width: 1.2,
            ),
            boxShadow: [BoxShadow(
              color: color.withValues(alpha: 0.2 * brightness),
              blurRadius: 6,
            )],
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: color,
              fontSize: 7,
              fontFamily: 'Courier',
              fontWeight: FontWeight.bold,
              height: 1.3,
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'ACTIVE TIER',
          style: TextStyle(
            color: color.withValues(alpha: 0.5),
            fontSize: 6,
            fontFamily: 'Courier',
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}

enum _ActiveNode { none, therapyDirector, storyWeaver, guardian }
