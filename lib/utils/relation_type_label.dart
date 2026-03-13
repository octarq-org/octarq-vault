import '../l10n/app_localizations.dart';

/// Stored relation type values (English, used in DB/API).
const relationTypeValues = [
  'Hosted On',
  'Depends On',
  'Uses',
  'Managed By',
  'Related To',
  'Linked Account',
];

String relationTypeLabel(AppLocalizations l10n, String value) {
  switch (value) {
    case 'Hosted On':
      return l10n.relationHostedOn;
    case 'Depends On':
      return l10n.relationDependsOn;
    case 'Uses':
      return l10n.relationUses;
    case 'Managed By':
      return l10n.relationManagedBy;
    case 'Related To':
      return l10n.relationRelatedTo;
    case 'Linked Account':
      return l10n.relationLinkedAccount;
    default:
      return value;
  }
}
