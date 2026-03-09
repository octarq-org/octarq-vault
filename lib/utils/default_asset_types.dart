import '../models/asset_type.dart';

const _billingCycleOptions = ['Monthly', 'Quarterly', 'Yearly', 'Lifetime'];
const _autoRenewOptions = ['Enabled', 'Disabled'];
const _cardTypeOptions = ['Debit', 'Credit', 'Prepaid'];
const _kycOptions = ['None', 'Level 1', 'Level 2', 'Level 3'];
const _tfaOptions = ['Disabled', 'TOTP', 'SMS', 'Hardware Key'];
const _subscriptionLevelOptions = ['Free', 'Pro', 'Team', 'Enterprise'];

final List<AssetType> defaultAssetTypes = [
  const AssetType(
    id: 'type_domain',
    name: '域名 (Domain)',
    icon: 'language',
    isBuiltIn: true,
    fieldSchema: [
      AssetTypeFieldSchema(key: 'registrar', label: '注册商', type: 'text', isRequired: true),
      AssetTypeFieldSchema(key: 'dns', label: 'DNS 配置', type: 'text'),
      AssetTypeFieldSchema(
        key: 'auto_renew',
        label: '自动续费',
        type: 'select',
        options: _autoRenewOptions,
      ),
      AssetTypeFieldSchema(
        key: 'billing_cycle',
        label: '计费周期',
        type: 'select',
        options: _billingCycleOptions,
      ),
      AssetTypeFieldSchema(key: 'cost', label: '费用', type: 'number'),
    ],
  ),
  const AssetType(
    id: 'type_ssl',
    name: 'SSL 证书',
    icon: 'security',
    isBuiltIn: true,
    fieldSchema: [
      AssetTypeFieldSchema(key: 'issuer', label: '颁发机构', type: 'text', isRequired: true),
      AssetTypeFieldSchema(key: 'domain_bind', label: '域名绑定', type: 'text'),
      AssetTypeFieldSchema(
        key: 'auto_renew',
        label: '自动续签',
        type: 'select',
        options: _autoRenewOptions,
      ),
      AssetTypeFieldSchema(
        key: 'billing_cycle',
        label: '计费周期',
        type: 'select',
        options: _billingCycleOptions,
      ),
      AssetTypeFieldSchema(key: 'cost', label: '费用', type: 'number'),
    ],
  ),
  const AssetType(
    id: 'type_vps',
    name: 'VPS / 云服务器',
    icon: 'dns',
    isBuiltIn: true,
    fieldSchema: [
      AssetTypeFieldSchema(key: 'provider', label: '服务商', type: 'text', isRequired: true),
      AssetTypeFieldSchema(key: 'ip', label: 'IP 地址', type: 'text'),
      AssetTypeFieldSchema(key: 'specs', label: '配置规格', type: 'text'),
      AssetTypeFieldSchema(
        key: 'billing_cycle',
        label: '费用周期',
        type: 'select',
        options: _billingCycleOptions,
      ),
      AssetTypeFieldSchema(key: 'cost', label: '费用', type: 'number'),
    ],
  ),
  const AssetType(
    id: 'type_email',
    name: '邮箱账号',
    icon: 'email',
    isBuiltIn: true,
    fieldSchema: [
      AssetTypeFieldSchema(key: 'provider', label: '服务商', type: 'text', isRequired: true),
      AssetTypeFieldSchema(key: 'password', label: '密码', type: 'password', isEncrypted: true, isRequired: true),
      AssetTypeFieldSchema(key: 'recovery_email', label: '恢复邮箱', type: 'text'),
      AssetTypeFieldSchema(key: 'phone_bind', label: '绑定手机', type: 'text'),
    ],
  ),
  const AssetType(
    id: 'type_account',
    name: '平台账号',
    icon: 'account_circle',
    isBuiltIn: true,
    fieldSchema: [
      AssetTypeFieldSchema(key: 'platform', label: '平台名', type: 'text', isRequired: true),
      AssetTypeFieldSchema(key: 'username', label: '用户名', type: 'text', isRequired: true),
      AssetTypeFieldSchema(key: 'password', label: '密码', type: 'password', isEncrypted: true, isRequired: true),
    ],
  ),
  const AssetType(
    id: 'type_bankcard',
    name: '银行卡 / 信用卡',
    icon: 'credit_card',
    isBuiltIn: true,
    fieldSchema: [
      AssetTypeFieldSchema(key: 'bank', label: '银行', type: 'text', isRequired: true),
      AssetTypeFieldSchema(
        key: 'card_type',
        label: '卡种',
        type: 'select',
        options: _cardTypeOptions,
      ),
      AssetTypeFieldSchema(key: 'card_number', label: '卡号后四位', type: 'text', isEncrypted: true),
      AssetTypeFieldSchema(key: 'cvv', label: 'CVV', type: 'password', isEncrypted: true),
      AssetTypeFieldSchema(key: 'billing_day', label: '账单日', type: 'number'),
    ],
  ),
  const AssetType(
    id: 'type_apikey',
    name: 'API Key / Token',
    icon: 'vpn_key',
    isBuiltIn: true,
    fieldSchema: [
      AssetTypeFieldSchema(key: 'platform', label: '平台', type: 'text', isRequired: true),
      AssetTypeFieldSchema(key: 'api_key', label: 'API Key', type: 'password', isEncrypted: true, isRequired: true),
      AssetTypeFieldSchema(key: 'permissions', label: '权限范围', type: 'text'),
    ],
  ),
  const AssetType(
    id: 'type_saas',
    name: 'SaaS 订阅',
    icon: 'subscriptions',
    isBuiltIn: true,
    fieldSchema: [
      AssetTypeFieldSchema(key: 'provider', label: '服务商', type: 'text', isRequired: true),
      AssetTypeFieldSchema(
        key: 'plan',
        label: '订阅计划',
        type: 'select',
        options: _subscriptionLevelOptions,
      ),
      AssetTypeFieldSchema(
        key: 'billing_cycle',
        label: '计费周期',
        type: 'select',
        options: _billingCycleOptions,
      ),
      AssetTypeFieldSchema(key: 'cost', label: '订阅费用', type: 'number'),
    ],
  ),
  const AssetType(
    id: 'type_exchange',
    name: '加密货币交易所',
    icon: 'currency_bitcoin',
    isBuiltIn: true,
    fieldSchema: [
      AssetTypeFieldSchema(key: 'exchange', label: '交易所名称', type: 'text', isRequired: true),
      AssetTypeFieldSchema(
        key: 'kyc_level',
        label: 'KYC 等级',
        type: 'select',
        options: _kycOptions,
      ),
      AssetTypeFieldSchema(
        key: 'tfa_status',
        label: '2FA 状态',
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
      AssetTypeFieldSchema(key: 'usage', label: '用途', type: 'text', isRequired: true),
      AssetTypeFieldSchema(key: 'fingerprint', label: '密钥指纹', type: 'text', isEncrypted: true),
      AssetTypeFieldSchema(key: 'server', label: '关联服务器', type: 'text'),
    ],
  ),
];
