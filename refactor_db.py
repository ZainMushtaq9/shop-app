import re
import os

file_path = r"c:\Users\Kashif\Documents\shop\lib\services\database_service.dart"

with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Update the singleton / DB getters
old_block = r"  SupabaseClient get _db => Supabase\.instance\.client;.*?String\? get _userId => _db\.auth\.currentUser\?\.id;"

new_block = """  SupabaseClient get _db => Supabase.instance.client;
  String? get _userIdVal => _db.auth.currentUser?.id;

  String? _cachedShopId;
  Future<String?> _getShopId() async {
    if (_cachedShopId != null) return _cachedShopId;
    final uid = _userIdVal;
    if (uid == null) return null;
    
    try {
      final res = await _db.from('shop_members').select('shop_id').eq('user_id', uid).maybeSingle();
      if (res != null) {
        _cachedShopId = res['shop_id'] as String;
      } else {
        // Auto-create shop for users
        final shopRes = await _db.from('shops').select('id').eq('owner_id', uid).maybeSingle();
        if (shopRes != null) {
          _cachedShopId = shopRes['id'] as String;
          await _db.from('shop_members').insert({'shop_id': _cachedShopId, 'user_id': uid, 'role': 'owner'});
        } else {
          final newShop = await _db.from('shops').insert({'owner_id': uid}).select('id').single();
          _cachedShopId = newShop['id'] as String;
          await _db.from('shop_members').insert({'shop_id': _cachedShopId, 'user_id': uid, 'role': 'owner'});
          await _db.from('shop_settings').insert({'shop_id': _cachedShopId});
        }
      }
    } catch (e) {
      print('Error auto-creating shop: $e');
    }
    return _cachedShopId;
  }"""

# Use dotall to match across newlines in varied endings
content = re.sub(old_block, new_block, content, flags=re.DOTALL)

# Replace all exact usages of _userId! and _userId
content = content.replace("_userId!", "(await _getShopId())!")
content = content.replace("_userId", "(await _getShopId())")

# Revert formatting damage to our new function from the blanket replace
content = content.replace("final uid = (await _getShopId())Val;", "final uid = _userIdVal;")

# DB column names 'user_id' -> 'shop_id'
content = content.replace("'user_id'", "'shop_id'")

# DB column names 'shopkeeper_id' -> 'shop_id'
content = content.replace("'shopkeeper_id'", "'shop_id'")

# Write changes
with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)

print(f"File updated. Size: {len(content)}")
