import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/project_state.dart';
import '../../theme/flowspace_colors.dart';

class BackgroundSkin extends StatelessWidget {
  final Widget child;

  const BackgroundSkin({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final projectState = Provider.of<ProjectState>(context);
    final templateId = projectState.currentProject?.templateId;

    Color bg;
    switch (templateId) {
      case 'whiteboard':
        bg = FlowspaceColors.whiteboardBg;
        break;
      case 'story':
        bg = FlowspaceColors.storyBg;
        break;
      case 'workflow':
        bg = FlowspaceColors.workflowBg;
        break;
      case 'brainstorm-lite':
        bg = FlowspaceColors.brainstormBg;
        break;
      case 'game':
        bg = FlowspaceColors.gameBg;
        break;
      case 'blank':
      default:
        bg = FlowspaceColors.blankBg;
    }

    return Container(
      color: bg,
      child: child,
    );
  }
}
