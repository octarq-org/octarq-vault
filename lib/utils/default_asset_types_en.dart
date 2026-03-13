import '../models/asset_type.dart';

const _billingCycleOptions = ['Monthly', 'Quarterly', 'Yearly', 'Lifetime'];
const _autoRenewOptions = ['Enabled', 'Disabled'];
const _cardTypeOptions = ['Debit', 'Credit', 'Prepaid'];
const _kycOptions = ['None', 'Level 1', 'Level 2', 'Level 3'];
const _tfaOptions = ['Disabled', 'TOTP', 'SMS', 'Hardware Key'];
const _subscriptionLevelOptions = ['Free', 'Pro', 'Team', 'Enterprise'];

List<AssetType> get defaultAssetTypesEn => [
  const AssetType(
    id: 'type_domain',
    name: 'Domain',
    icon: 'language',
    isBuiltIn: true,
    fieldSchema: [
      AssetTypeFieldSchema(
        key: 'registrar',
        label: 'Registrar',
        type: 'text',
        isRequired: true,
      ),
      AssetTypeFieldSchema(key: 'dns', label: 'DNS', type: 'text'),
      AssetTypeFieldSchema(
        key: 'auto_renew',
        label: 'Auto Renew',
        type: 'select',
        options: _autoRenewOptions,
      ),
      AssetTypeFieldSchema(
        key: 'billing_cycle',
        label: 'Billing Cycle',
        type: 'select',
        options: _billingCycleOptions,
      ),
      AssetTypeFieldSchema(key: 'cost', label: 'Cost', type: 'number'),
    ],
  ),
  const AssetType(
    id: 'type_ssl',
    name: 'SSL Certificate',
    icon: 'security',
    isBuiltIn: true,
    fieldSchema: [
      AssetTypeFieldSchema(
        key: 'issuer',
        label: 'Issuer',
        type: 'text',
        isRequired: true,
      ),
      AssetTypeFieldSchema(key: 'domain_bind', label: 'Domain', type: 'text'),
      AssetTypeFieldSchema(
        key: 'auto_renew',
        label: 'Auto Renew',
        type: 'select',
        options: _autoRenewOptions,
      ),
      AssetTypeFieldSchema(
        key: 'billing_cycle',
        label: 'Billing Cycle',
        type: 'select',
        options: _billingCycleOptions,
      ),
      AssetTypeFieldSchema(key: 'cost', label: 'Cost', type: 'number'),
    ],
  ),
  const AssetType(
    id: 'type_vps',
    name: 'VPS / Cloud Server',
    icon: 'dns',
    isBuiltIn: true,
    fieldSchema: [
      AssetTypeFieldSchema(
        key: 'provider',
        label: 'Provider',
        type: 'text',
        isRequired: true,
      ),
      AssetTypeFieldSchema(key: 'ip', label: 'IP Address', type: 'text'),
      AssetTypeFieldSchema(key: 'specs', label: 'Specs', type: 'text'),
      AssetTypeFieldSchema(
        key: 'billing_cycle',
        label: 'Billing Cycle',
        type: 'select',
        options: _billingCycleOptions,
      ),
      AssetTypeFieldSchema(key: 'cost', label: 'Cost', type: 'number'),
    ],
  ),
  const AssetType(
    id: 'type_email',
    name: 'Email Account',
    icon: 'email',
    isBuiltIn: true,
    fieldSchema: [
      AssetTypeFieldSchema(
        key: 'provider',
        label: 'Provider',
        type: 'text',
        isRequired: true,
      ),
      AssetTypeFieldSchema(
        key: 'password',
        label: 'Password',
        type: 'password',
        isEncrypted: true,
        isRequired: true,
      ),
      AssetTypeFieldSchema(
        key: 'recovery_email',
        label: 'Recovery Email',
        type: 'text',
      ),
      AssetTypeFieldSchema(key: 'phone_bind', label: 'Phone', type: 'text'),
    ],
  ),
  const AssetType(
    id: 'type_account',
    name: 'Platform Account',
    icon: 'account_circle',
    isBuiltIn: true,
    fieldSchema: [
      AssetTypeFieldSchema(
        key: 'platform',
        label: 'Platform',
        type: 'text',
        isRequired: true,
      ),
      AssetTypeFieldSchema(
        key: 'username',
        label: 'Username',
        type: 'text',
        isRequired: true,
      ),
      AssetTypeFieldSchema(
        key: 'password',
        label: 'Password',
        type: 'password',
        isEncrypted: true,
        isRequired: true,
      ),
    ],
  ),
  const AssetType(
    id: 'type_bankcard',
    name: 'Bank / Credit Card',
    icon: 'credit_card',
    isBuiltIn: true,
    fieldSchema: [
      AssetTypeFieldSchema(
        key: 'bank',
        label: 'Bank',
        type: 'text',
        isRequired: true,
      ),
      AssetTypeFieldSchema(
        key: 'card_type',
        label: 'Card Type',
        type: 'select',
        options: _cardTypeOptions,
      ),
      AssetTypeFieldSchema(
        key: 'card_number',
        label: 'Last 4 Digits',
        type: 'text',
        isEncrypted: true,
      ),
      AssetTypeFieldSchema(
        key: 'cvv',
        label: 'CVV',
        type: 'password',
        isEncrypted: true,
      ),
      AssetTypeFieldSchema(
        key: 'billing_day',
        label: 'Billing Day',
        type: 'number',
      ),
    ],
  ),
  const AssetType(
    id: 'type_apikey',
    name: 'API Key / Token',
    icon: 'vpn_key',
    isBuiltIn: true,
    fieldSchema: [
      AssetTypeFieldSchema(
        key: 'platform',
        label: 'Platform',
        type: 'text',
        isRequired: true,
      ),
      AssetTypeFieldSchema(
        key: 'api_key',
        label: 'API Key',
        type: 'password',
        isEncrypted: true,
        isRequired: true,
      ),
      AssetTypeFieldSchema(
        key: 'permissions',
        label: 'Permissions',
        type: 'text',
      ),
    ],
  ),
  const AssetType(
    id: 'type_saas',
    name: 'SaaS Subscription',
    icon: 'subscriptions',
    isBuiltIn: true,
    fieldSchema: [
      AssetTypeFieldSchema(
        key: 'provider',
        label: 'Provider',
        type: 'text',
        isRequired: true,
      ),
      AssetTypeFieldSchema(
        key: 'plan',
        label: 'Plan',
        type: 'select',
        options: _subscriptionLevelOptions,
      ),
      AssetTypeFieldSchema(
        key: 'billing_cycle',
        label: 'Billing Cycle',
        type: 'select',
        options: _billingCycleOptions,
      ),
      AssetTypeFieldSchema(key: 'cost', label: 'Cost', type: 'number'),
    ],
  ),
  const AssetType(
    id: 'type_exchange',
    name: 'Crypto Exchange',
    icon: 'currency_bitcoin',
    isBuiltIn: true,
    fieldSchema: [
      AssetTypeFieldSchema(
        key: 'exchange',
        label: 'Exchange',
        type: 'text',
        isRequired: true,
      ),
      AssetTypeFieldSchema(
        key: 'kyc_level',
        label: 'KYC Level',
        type: 'select',
        options: _kycOptions,
      ),
      AssetTypeFieldSchema(
        key: 'tfa_status',
        label: '2FA',
        type: 'select',
        options: _tfaOptions,
      ),
    ],
  ),
  const AssetType(
    id: 'type_ssh',
    name: 'SSH Key',
    icon: 'terminal',
    isBuiltIn: true,
    fieldSchema: [
      AssetTypeFieldSchema(
        key: 'usage',
        label: 'Usage',
        type: 'text',
        isRequired: true,
      ),
      AssetTypeFieldSchema(
        key: 'fingerprint',
        label: 'Fingerprint',
        type: 'text',
        isEncrypted: true,
      ),
      AssetTypeFieldSchema(key: 'server', label: 'Server', type: 'text'),
    ],
  ),
];
