import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../l10n/app_strings.dart';
import '../../theme/app_theme.dart';
import '../../services/database_service.dart';

class CustomerPortalQRScreen extends ConsumerStatefulWidget {
  const CustomerPortalQRScreen({super.key});

  @override
  ConsumerState<CustomerPortalQRScreen> createState() => _CustomerPortalQRScreenState();
}

class _CustomerPortalQRScreenState extends ConsumerState<CustomerPortalQRScreen> {
  String? _shopId;

  @override
  void initState() {
    super.initState();
    _loadShopId();
  }
  
  Future<void> _loadShopId() async {
    final db = ref.read(databaseProvider);
    final id = await db.getShopId();
    if (mounted) setState(() => _shopId = id);
  }

  @override
  Widget build(BuildContext context) {
    // Ensure production URL once deployed
    const portalUrl = "https://superbusinessshop-app.web.app/#/customer";
    
    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.isUrdu ? 'گاہک پورٹل QR' : 'Customer Portal QR'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                AppStrings.isUrdu ? 'اپنے گاہکوں کو یہ QR کوڈ دکھائیں' : 'Show this QR to your customers',
                textAlign: TextAlign.center,
                style: AppTextStyles.urduTitle.copyWith(fontSize: 20),
              ),
              const SizedBox(height: 16),
              Text(
                AppStrings.isUrdu 
                  ? 'وہ اسے اسکین کر کے اپنا کھاتہ اور بل اپنے موبائل پر دیکھ سکتے ہیں' 
                  : 'They can scan it to view their ledger directly on their mobile phone',
                textAlign: TextAlign.center,
                style: AppTextStyles.urduBody.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 48),
              if (_shopId != null)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 20)],
                  ),
                  child: QrImageView(
                    data: portalUrl,
                    version: QrVersions.auto,
                    size: 250.0,
                    foregroundColor: AppColors.primaryDark,
                  ),
                )
              else 
                const CircularProgressIndicator(),
            ],
          ),
        ),
      ),
    );
  }
}
