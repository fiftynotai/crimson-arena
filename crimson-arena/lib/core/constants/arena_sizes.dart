/// Centralized dimension constants for the Crimson Arena dashboard.
///
/// Collects the hardcoded magic numbers scattered across widget files
/// into a single source of truth. Widgets should reference these
/// constants instead of embedding raw numeric literals.
class ArenaSizes {
  ArenaSizes._();

  // ---------------------------------------------------------------------------
  // Navigation
  // ---------------------------------------------------------------------------

  /// Height of the top navigation bar in [ArenaScaffold].
  static const double navBarHeight = 56;

  // ---------------------------------------------------------------------------
  // Monogram / avatar circles
  // ---------------------------------------------------------------------------

  /// Large monogram circle diameter (agent grid cards).
  static const double monogramLarge = 40;

  /// Small icon circle diameter (achievement cards).
  static const double iconCircleSmall = 36;

  // ---------------------------------------------------------------------------
  // Status dots
  // ---------------------------------------------------------------------------

  /// Standard status dot diameter (connection badges, vital indicators).
  static const double statusDotDefault = 6;

  /// Large status dot diameter (instance card headers).
  static const double statusDotLarge = 8;

  // ---------------------------------------------------------------------------
  // Progress bars
  // ---------------------------------------------------------------------------

  /// Height of the segmented HP / context bar.
  static const double segmentedBarHeight = 8;

  /// Height of token breakdown bars.
  static const double tokenBarHeight = 6;

  /// Height of level progress bars in agent cards.
  static const double levelProgressHeight = 4;

  /// Height of compact gauge progress bars in the instrument strip.
  static const double gaugeProgressHeight = 3;

  /// Segment gap width in segmented bars.
  static const double segmentGap = 2;

  // ---------------------------------------------------------------------------
  // RPG stat bars
  // ---------------------------------------------------------------------------

  /// Height of a full-size RPG stat bar (agent grid).
  static const double rpgStatBarHeight = 4;

  // ---------------------------------------------------------------------------
  // Column widths (table layouts)
  // ---------------------------------------------------------------------------

  /// Width of the project column in brief rows.
  static const double briefProjectColumnWidth = 64;

  /// Width of the brief ID column in brief rows.
  static const double briefIdColumnWidth = 72;

  /// Width of the priority column in brief rows.
  static const double briefPriorityColumnWidth = 28;

  /// Width of the token bar label column.
  static const double tokenBarLabelWidth = 64;

  /// Width of the token bar value column.
  static const double tokenBarValueWidth = 48;

  /// Width of the token bar percentage column.
  static const double tokenBarPercentWidth = 32;

  /// Width of the RPG stat label column.
  static const double rpgStatLabelWidth = 28;

  /// Width of the RPG stat value column.
  static const double rpgStatValueWidth = 24;

  // ---------------------------------------------------------------------------
  // Detail panels
  // ---------------------------------------------------------------------------

  /// Height of the agent detail panel in wide layout.
  static const double agentDetailPanelHeight = 520;

  /// Height of the agent detail panel in narrow layout.
  static const double agentDetailPanelNarrowHeight = 420;

  // ---------------------------------------------------------------------------
  // Instrument strip
  // ---------------------------------------------------------------------------

  /// Width of the mini gauge progress bar in the instrument strip.
  static const double instrumentGaugeWidth = 80;

  /// Height of the divider between instrument gauges.
  static const double instrumentDividerHeight = 32;

  // ---------------------------------------------------------------------------
  // Battle log
  // ---------------------------------------------------------------------------

  /// Height of the battle log scrollable list.
  static const double battleLogHeight = 280;

  // ---------------------------------------------------------------------------
  // Skill heatmap
  // ---------------------------------------------------------------------------

  /// Width of the skill name label column.
  static const double skillNameWidth = 100;

  /// Width of the skill invocation count column.
  static const double skillCountWidth = 36;

  /// Height of a skill heatmap bar.
  static const double skillBarHeight = 10;

  // ---------------------------------------------------------------------------
  // Brief velocity / status bars
  // ---------------------------------------------------------------------------

  /// Height of the brief velocity status bar.
  static const double statusBarHeight = 10;

  // ---------------------------------------------------------------------------
  // Cost estimate
  // ---------------------------------------------------------------------------

  /// Diameter of the color dot in cost rows.
  static const double costDotSize = 4;

  // ---------------------------------------------------------------------------
  // Skill cards
  // ---------------------------------------------------------------------------

  /// Aspect ratio for skill game cards (width:height).
  static const double skillCardAspectRatio = 0.75;

  /// Border width of skill card frames.
  static const double skillCardBorderWidth = 1.5;

  /// Diameter of agent monogram circles on skill cards.
  static const double skillCardMonogramSize = 24;

  /// Height of the usage progress bar on skill cards.
  static const double skillCardUsageBarHeight = 6;

  // ---------------------------------------------------------------------------
  // Context breakdown
  // ---------------------------------------------------------------------------

  /// Height of the stacked context breakdown bar.
  static const double breakdownBarHeight = 12;

  /// Diameter of legend color dots.
  static const double breakdownLegendDotSize = 8;

  /// Width of the legend token value column.
  static const double breakdownLegendValueWidth = 56;

  // ---------------------------------------------------------------------------
  // Task kanban
  // ---------------------------------------------------------------------------

  /// Micro gap for sub-token spacing (2px) -- priority dots, icon-label gaps.
  static const double microGap = 2;

  /// Vertical padding for compact badges (1px).
  static const double badgeVerticalPadding = 1;

  /// Font size for micro monospaced text (9px) -- replaces labelSmall - 1 arithmetic.
  static const double monoFontSizeMicro = 9;

  /// Fixed width of the agent name column in the workload bar.
  static const double workloadAgentNameWidth = 100;

  /// Height of workload bar tracks.
  static const double workloadBarHeight = 14;

  /// Width of the workload count label column.
  static const double workloadCountWidth = 24;

  // ---------------------------------------------------------------------------
  // Heartbeat pulse
  // ---------------------------------------------------------------------------

  /// Duration of one heartbeat pulse cycle.
  static const Duration heartbeatDuration = Duration(milliseconds: 1500);

  /// Blur radius of the heartbeat dot glow.
  static const double heartbeatBlurRadius = 6;

  /// Spread radius of the heartbeat dot glow.
  static const double heartbeatSpreadRadius = 1;
}
