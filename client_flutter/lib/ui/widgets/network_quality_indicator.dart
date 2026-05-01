import 'package:flutter/material.dart';
import '../../services/network_quality_service.dart';

class NetworkQualityIndicator extends StatelessWidget {
  final NetworkQuality quality;
  final int? latencyMs;
  final bool showText;
  final bool showLatency;
  final double size;

  const NetworkQualityIndicator({
    Key? key,
    required this.quality,
    this.latencyMs,
    this.showText = false,
    this.showLatency = false,
    this.size = 16,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildIcon(),
        if (showText || showLatency) const SizedBox(width: 4),
        if (showText)
          Text(
            _getQualityText(),
            style: TextStyle(
              fontSize: size * 0.75,
              color: _getColor(),
            ),
          ),
        if (showLatency && latencyMs != null)
          Text(
            '${latencyMs}ms',
            style: TextStyle(
              fontSize: size * 0.7,
              color: Colors.grey[600],
            ),
          ),
      ],
    );
  }

  Widget _buildIcon() {
    return Icon(
      _getIcon(),
      size: size,
      color: _getColor(),
    );
  }

  IconData _getIcon() {
    switch (quality) {
      case NetworkQuality.excellent:
        return Icons.signal_cellular_4_bar;
      case NetworkQuality.good:
        return Icons.signal_cellular_alt;
      case NetworkQuality.fair:
        return Icons.signal_cellular_alt_2_bar;
      case NetworkQuality.poor:
        return Icons.signal_cellular_alt_1_bar;
      case NetworkQuality.offline:
        return Icons.signal_cellular_off;
    }
  }

  Color _getColor() {
    switch (quality) {
      case NetworkQuality.excellent:
        return Colors.green;
      case NetworkQuality.good:
        return Colors.lightGreen;
      case NetworkQuality.fair:
        return Colors.orange;
      case NetworkQuality.poor:
        return Colors.red;
      case NetworkQuality.offline:
        return Colors.grey;
    }
  }

  String _getQualityText() {
    switch (quality) {
      case NetworkQuality.excellent:
        return 'Excellent';
      case NetworkQuality.good:
        return 'Good';
      case NetworkQuality.fair:
        return 'Fair';
      case NetworkQuality.poor:
        return 'Poor';
      case NetworkQuality.offline:
        return 'Offline';
    }
  }
}

/// Animated network quality indicator with pulse effect
class AnimatedNetworkQualityIndicator extends StatefulWidget {
  final Stream<NetworkQualityMetrics> metricsStream;
  final bool showText;
  final bool showLatency;
  final double size;

  const AnimatedNetworkQualityIndicator({
    Key? key,
    required this.metricsStream,
    this.showText = false,
    this.showLatency = false,
    this.size = 16,
  }) : super(key: key);

  @override
  State<AnimatedNetworkQualityIndicator> createState() =>
      _AnimatedNetworkQualityIndicatorState();
}

class _AnimatedNetworkQualityIndicatorState
    extends State<AnimatedNetworkQualityIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  NetworkQualityMetrics? _metrics;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    widget.metricsStream.listen((metrics) {
      if (mounted) {
        setState(() {
          _metrics = metrics;
        });

        if (metrics.quality == NetworkQuality.poor ||
            metrics.quality == NetworkQuality.offline) {
          _controller.repeat(reverse: true);
        } else {
          _controller.stop();
          _controller.value = 1.0;
        }
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_metrics == null) {
      return const SizedBox.shrink();
    }

    return FadeTransition(
      opacity: _controller,
      child: NetworkQualityIndicator(
        quality: _metrics!.quality,
        latencyMs: _metrics!.latencyMs,
        showText: widget.showText,
        showLatency: widget.showLatency,
        size: widget.size,
      ),
    );
  }
}

/// Banner shown when offline or poor connection
class NetworkQualityBanner extends StatelessWidget {
  final NetworkQuality quality;
  final VoidCallback? onRetry;

  const NetworkQualityBanner({
    Key? key,
    required this.quality,
    this.onRetry,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (quality == NetworkQuality.excellent ||
        quality == NetworkQuality.good) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: _getBackgroundColor(),
      child: Row(
        children: [
          Icon(
            _getIcon(),
            color: Colors.white,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _getTitle(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  _getMessage(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (onRetry != null && quality == NetworkQuality.offline)
            TextButton(
              onPressed: onRetry,
              child: const Text(
                'Retry',
                style: TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }

  Color _getBackgroundColor() {
    switch (quality) {
      case NetworkQuality.fair:
        return Colors.orange;
      case NetworkQuality.poor:
        return Colors.deepOrange;
      case NetworkQuality.offline:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getIcon() {
    switch (quality) {
      case NetworkQuality.fair:
        return Icons.signal_cellular_alt_2_bar;
      case NetworkQuality.poor:
        return Icons.signal_cellular_alt_1_bar;
      case NetworkQuality.offline:
        return Icons.cloud_off;
      default:
        return Icons.info;
    }
  }

  String _getTitle() {
    switch (quality) {
      case NetworkQuality.fair:
        return 'Slow connection';
      case NetworkQuality.poor:
        return 'Poor connection';
      case NetworkQuality.offline:
        return 'No connection';
      default:
        return 'Connection issue';
    }
  }

  String _getMessage() {
    switch (quality) {
      case NetworkQuality.fair:
        return 'Messages may take longer to send';
      case NetworkQuality.poor:
        return 'Messages may fail to send';
      case NetworkQuality.offline:
        return 'Messages will be sent when connection is restored';
      default:
        return 'Check your connection';
    }
  }
}

/// Queue size indicator showing offline messages
class QueueSizeIndicator extends StatelessWidget {
  final int queueSize;
  final VoidCallback? onTap;

  const QueueSizeIndicator({
    Key? key,
    required this.queueSize,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (queueSize == 0) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.orange,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.schedule,
              size: 16,
              color: Colors.white,
            ),
            const SizedBox(width: 4),
            Text(
              '$queueSize queued',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
