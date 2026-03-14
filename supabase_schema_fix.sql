-- ═══════════════════════════════════════════════════════════════════
-- SUPER BUSINESS SHOP — COMPLETE SUPABASE SCHEMA (Fresh Install)
-- Run this ENTIRE script in Supabase SQL Editor → New Query → Run
-- ═══════════════════════════════════════════════════════════════════

-- ══════════════════════════════════════════
-- HELPER FUNCTION
-- ══════════════════════════════════════════
CREATE OR REPLACE FUNCTION public.is_shop_member(check_shop_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM public.shop_members
    WHERE shop_id = check_shop_id
    AND user_id = auth.uid()
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ══════════════════════════════════════════
-- 1. SHOPS
-- ══════════════════════════════════════════
CREATE TABLE public.shops (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);
ALTER TABLE public.shops ENABLE ROW LEVEL SECURITY;
CREATE POLICY "shop_owner" ON public.shops
  FOR ALL USING (owner_id = auth.uid());

-- ══════════════════════════════════════════
-- 2. SHOP MEMBERS (RBAC)
-- ══════════════════════════════════════════
CREATE TABLE public.shop_members (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  shop_id UUID NOT NULL REFERENCES public.shops(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  role VARCHAR(20) NOT NULL DEFAULT 'owner'
    CHECK (role IN ('owner','salesperson','accountant')),
  status VARCHAR(20) DEFAULT 'active'
    CHECK (status IN ('active','suspended')),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(shop_id, user_id)
);
ALTER TABLE public.shop_members ENABLE ROW LEVEL SECURITY;
CREATE POLICY "members_view" ON public.shop_members
  FOR SELECT USING (user_id = auth.uid() OR shop_id IN (
    SELECT shop_id FROM public.shop_members WHERE user_id = auth.uid()
  ));
CREATE POLICY "members_manage" ON public.shop_members
  FOR ALL USING (shop_id IN (
    SELECT shop_id FROM public.shop_members
    WHERE user_id = auth.uid() AND role = 'owner'
  ));

-- ══════════════════════════════════════════
-- 3. SHOP SETTINGS
-- ══════════════════════════════════════════
CREATE TABLE public.shop_settings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  shop_id UUID NOT NULL REFERENCES public.shops(id) ON DELETE CASCADE UNIQUE,
  shop_name_en VARCHAR(100) DEFAULT 'Super Business Shop',
  shop_name_ur VARCHAR(100) DEFAULT 'سپر بزنس شاپ',
  shop_type VARCHAR(50) DEFAULT 'general',
  owner_name VARCHAR(100),
  phone VARCHAR(20),
  address TEXT,
  city VARCHAR(50),
  logo_url TEXT,
  primary_color VARCHAR(7) DEFAULT '#006D77',
  dark_mode VARCHAR(10) DEFAULT 'system'
    CHECK (dark_mode IN ('light','dark','system')),
  language VARCHAR(5) DEFAULT 'en'
    CHECK (language IN ('en','ur')),
  bill_show_logo BOOLEAN DEFAULT TRUE,
  bill_tagline TEXT,
  bill_footer_msg TEXT DEFAULT 'Shukriya! Dobara zaroor tashreef laein',
  bill_show_phone BOOLEAN DEFAULT TRUE,
  bill_show_addr BOOLEAN DEFAULT FALSE,
  bill_number_prefix VARCHAR(6) DEFAULT 'BILL',
  bill_next_number INT DEFAULT 1,
  updated_at TIMESTAMPTZ DEFAULT NOW()
);
ALTER TABLE public.shop_settings ENABLE ROW LEVEL SECURITY;
CREATE POLICY "settings_access" ON public.shop_settings
  FOR ALL USING (public.is_shop_member(shop_id))
  WITH CHECK (public.is_shop_member(shop_id));

-- ══════════════════════════════════════════
-- 4. PRODUCTS
-- ══════════════════════════════════════════
CREATE TABLE public.products (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  shop_id UUID NOT NULL REFERENCES public.shops(id) ON DELETE CASCADE,
  name_en TEXT NOT NULL DEFAULT '',
  name_ur TEXT,
  barcode TEXT,
  cost_price REAL NOT NULL DEFAULT 0,
  sale_price REAL NOT NULL DEFAULT 0,
  stock INTEGER NOT NULL DEFAULT 0,
  category TEXT DEFAULT 'General',
  image_url TEXT,
  is_active BOOLEAN DEFAULT TRUE,
  last_updated TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(shop_id, barcode)
);
ALTER TABLE public.products ENABLE ROW LEVEL SECURITY;
CREATE POLICY "products_access" ON public.products
  FOR ALL USING (public.is_shop_member(shop_id))
  WITH CHECK (public.is_shop_member(shop_id));
CREATE INDEX idx_products_shop ON public.products(shop_id);

-- ══════════════════════════════════════════
-- 5. CUSTOMERS
-- ══════════════════════════════════════════
CREATE TABLE public.customers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  shop_id UUID NOT NULL REFERENCES public.shops(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  phone TEXT,
  balance REAL NOT NULL DEFAULT 0.0,
  last_updated TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(shop_id, phone)
);
ALTER TABLE public.customers ENABLE ROW LEVEL SECURITY;
CREATE POLICY "customers_access" ON public.customers
  FOR ALL USING (public.is_shop_member(shop_id))
  WITH CHECK (public.is_shop_member(shop_id));
CREATE INDEX idx_customers_shop ON public.customers(shop_id);
CREATE INDEX idx_customers_phone ON public.customers(phone);

-- ══════════════════════════════════════════
-- 6. SUPPLIERS
-- ══════════════════════════════════════════
CREATE TABLE public.suppliers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  shop_id UUID NOT NULL REFERENCES public.shops(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  business_name TEXT,
  phone TEXT,
  balance REAL NOT NULL DEFAULT 0.0,
  last_updated TIMESTAMPTZ DEFAULT NOW()
);
ALTER TABLE public.suppliers ENABLE ROW LEVEL SECURITY;
CREATE POLICY "suppliers_access" ON public.suppliers
  FOR ALL USING (public.is_shop_member(shop_id))
  WITH CHECK (public.is_shop_member(shop_id));

-- ══════════════════════════════════════════
-- 7. SALES
-- ══════════════════════════════════════════
CREATE TABLE public.sales (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  shop_id UUID NOT NULL REFERENCES public.shops(id) ON DELETE CASCADE,
  customer_id UUID REFERENCES public.customers(id) ON DELETE SET NULL,
  bill_number VARCHAR(50),
  date TIMESTAMPTZ DEFAULT NOW(),
  subtotal REAL NOT NULL DEFAULT 0,
  discount_amount REAL DEFAULT 0.0,
  discount_percentage REAL DEFAULT 0.0,
  tax REAL DEFAULT 0.0,
  total REAL NOT NULL DEFAULT 0,
  profit REAL NOT NULL DEFAULT 0,
  payment_type VARCHAR(20) DEFAULT 'CASH',
  amount_paid REAL NOT NULL DEFAULT 0,
  balance_due REAL NOT NULL DEFAULT 0,
  status VARCHAR(20) DEFAULT 'COMPLETED'
    CHECK (status IN ('COMPLETED','CANCELLED','DRAFT')),
  hidden_from_customer BOOLEAN DEFAULT FALSE,
  is_synced BOOLEAN DEFAULT TRUE
);
ALTER TABLE public.sales ENABLE ROW LEVEL SECURITY;
CREATE POLICY "sales_access" ON public.sales
  FOR ALL USING (public.is_shop_member(shop_id))
  WITH CHECK (public.is_shop_member(shop_id));
CREATE INDEX idx_sales_shop_date ON public.sales(shop_id, date);

-- ══════════════════════════════════════════
-- 8. SALE ITEMS
-- ══════════════════════════════════════════
CREATE TABLE public.sale_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  sale_id UUID NOT NULL REFERENCES public.sales(id) ON DELETE CASCADE,
  product_id UUID REFERENCES public.products(id) ON DELETE SET NULL,
  product_name TEXT,
  quantity REAL NOT NULL,
  purchase_price REAL NOT NULL DEFAULT 0,
  sale_price REAL NOT NULL DEFAULT 0
);
ALTER TABLE public.sale_items ENABLE ROW LEVEL SECURITY;
CREATE POLICY "sale_items_access" ON public.sale_items
  FOR ALL USING (EXISTS (
    SELECT 1 FROM public.sales s
    WHERE s.id = sale_items.sale_id
    AND public.is_shop_member(s.shop_id)
  ))
  WITH CHECK (EXISTS (
    SELECT 1 FROM public.sales s
    WHERE s.id = sale_items.sale_id
    AND public.is_shop_member(s.shop_id)
  ));
CREATE INDEX idx_sale_items_sale ON public.sale_items(sale_id);

-- ══════════════════════════════════════════
-- 9. INSTALLMENTS (Customer Payments)
-- ══════════════════════════════════════════
CREATE TABLE public.installments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  shop_id UUID NOT NULL REFERENCES public.shops(id) ON DELETE CASCADE,
  customer_id UUID NOT NULL REFERENCES public.customers(id) ON DELETE CASCADE,
  date TIMESTAMPTZ DEFAULT NOW(),
  amount REAL DEFAULT 0,
  type TEXT DEFAULT 'payment',
  description TEXT DEFAULT '',
  created_at TIMESTAMPTZ DEFAULT NOW()
);
ALTER TABLE public.installments ENABLE ROW LEVEL SECURITY;
CREATE POLICY "installments_access" ON public.installments
  FOR ALL USING (public.is_shop_member(shop_id))
  WITH CHECK (public.is_shop_member(shop_id));

-- ══════════════════════════════════════════
-- 10. SUPPLIER TRANSACTIONS
-- ══════════════════════════════════════════
CREATE TABLE public.supplier_transactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  shop_id UUID NOT NULL REFERENCES public.shops(id) ON DELETE CASCADE,
  supplier_id UUID NOT NULL REFERENCES public.suppliers(id) ON DELETE CASCADE,
  date TIMESTAMPTZ DEFAULT NOW(),
  amount REAL DEFAULT 0,
  type TEXT DEFAULT 'payment',
  description TEXT DEFAULT '',
  created_at TIMESTAMPTZ DEFAULT NOW()
);
ALTER TABLE public.supplier_transactions ENABLE ROW LEVEL SECURITY;
CREATE POLICY "supplier_tx_access" ON public.supplier_transactions
  FOR ALL USING (public.is_shop_member(shop_id))
  WITH CHECK (public.is_shop_member(shop_id));

-- ══════════════════════════════════════════
-- 11. EXPENSES
-- ══════════════════════════════════════════
CREATE TABLE public.expenses (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  shop_id UUID NOT NULL REFERENCES public.shops(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  amount REAL NOT NULL,
  category TEXT DEFAULT 'General',
  date TIMESTAMPTZ DEFAULT NOW(),
  payment_method VARCHAR(50),
  receipt_url TEXT,
  is_recurring BOOLEAN DEFAULT FALSE,
  recurring_pattern VARCHAR(50),
  last_updated TIMESTAMPTZ DEFAULT NOW()
);
ALTER TABLE public.expenses ENABLE ROW LEVEL SECURITY;
CREATE POLICY "expenses_access" ON public.expenses
  FOR ALL USING (public.is_shop_member(shop_id))
  WITH CHECK (public.is_shop_member(shop_id));
CREATE INDEX idx_expenses_shop_date ON public.expenses(shop_id, date);

-- ══════════════════════════════════════════
-- 12. RETURNS
-- ══════════════════════════════════════════
CREATE TABLE public.returns (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  shop_id UUID NOT NULL REFERENCES public.shops(id) ON DELETE CASCADE,
  original_sale_id UUID REFERENCES public.sales(id) ON DELETE SET NULL,
  customer_id UUID REFERENCES public.customers(id) ON DELETE SET NULL,
  return_number VARCHAR(50),
  date TIMESTAMPTZ DEFAULT NOW(),
  type VARCHAR(20) CHECK (type IN ('CUSTOMER','SUPPLIER')),
  total_amount REAL NOT NULL
);
ALTER TABLE public.returns ENABLE ROW LEVEL SECURITY;
CREATE POLICY "returns_access" ON public.returns
  FOR ALL USING (public.is_shop_member(shop_id))
  WITH CHECK (public.is_shop_member(shop_id));

-- ══════════════════════════════════════════
-- 13. RETURN ITEMS
-- ══════════════════════════════════════════
CREATE TABLE public.return_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  return_id UUID NOT NULL REFERENCES public.returns(id) ON DELETE CASCADE,
  product_id UUID REFERENCES public.products(id) ON DELETE SET NULL,
  quantity REAL NOT NULL,
  price REAL NOT NULL,
  condition VARCHAR(20) CHECK (condition IN ('Good','Damaged','Expired'))
);
ALTER TABLE public.return_items ENABLE ROW LEVEL SECURITY;
CREATE POLICY "return_items_access" ON public.return_items
  FOR ALL USING (EXISTS (
    SELECT 1 FROM public.returns r
    WHERE r.id = return_items.return_id
    AND public.is_shop_member(r.shop_id)
  ))
  WITH CHECK (EXISTS (
    SELECT 1 FROM public.returns r
    WHERE r.id = return_items.return_id
    AND public.is_shop_member(r.shop_id)
  ));

-- ══════════════════════════════════════════
-- 14. DAILY CASH SESSIONS
-- ══════════════════════════════════════════
CREATE TABLE public.daily_cash_sessions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  shop_id UUID NOT NULL REFERENCES public.shops(id) ON DELETE CASCADE,
  date DATE DEFAULT CURRENT_DATE,
  opening_balance REAL NOT NULL DEFAULT 0,
  closing_balance REAL,
  expected_closing REAL,
  difference REAL,
  status VARCHAR(20) DEFAULT 'OPEN'
    CHECK (status IN ('OPEN','CLOSED')),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(shop_id, date)
);
ALTER TABLE public.daily_cash_sessions ENABLE ROW LEVEL SECURITY;
CREATE POLICY "daily_cash_access" ON public.daily_cash_sessions
  FOR ALL USING (public.is_shop_member(shop_id))
  WITH CHECK (public.is_shop_member(shop_id));

-- ══════════════════════════════════════════
-- 15. CUSTOMER ACCOUNTS (Portal Login)
-- ══════════════════════════════════════════
CREATE TABLE public.customer_accounts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  phone VARCHAR(20) NOT NULL UNIQUE,
  name VARCHAR(120),
  is_active BOOLEAN DEFAULT TRUE,
  login_count INT DEFAULT 0,
  last_seen_shop_id UUID REFERENCES public.shops(id),
  last_login TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX idx_ca_phone ON public.customer_accounts(phone);
ALTER TABLE public.customer_accounts ENABLE ROW LEVEL SECURITY;
CREATE POLICY "ca_public_read" ON public.customer_accounts
  FOR SELECT USING (true);
CREATE POLICY "ca_insert" ON public.customer_accounts
  FOR INSERT WITH CHECK (true);
CREATE POLICY "ca_update" ON public.customer_accounts
  FOR UPDATE USING (true);

-- ══════════════════════════════════════════
-- 16. CUSTOMER NOTIFICATIONS
-- ══════════════════════════════════════════
CREATE TABLE public.customer_notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  customer_account_id UUID REFERENCES public.customer_accounts(id),
  customer_phone TEXT,
  shop_id UUID REFERENCES public.shops(id),
  type VARCHAR(30) DEFAULT 'new_bill',
  title TEXT NOT NULL,
  body TEXT NOT NULL,
  reference_id UUID,
  is_read BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX idx_cn_customer ON public.customer_notifications(customer_account_id);
ALTER TABLE public.customer_notifications ENABLE ROW LEVEL SECURITY;
CREATE POLICY "cn_public_read" ON public.customer_notifications
  FOR SELECT USING (true);
CREATE POLICY "cn_insert" ON public.customer_notifications
  FOR INSERT WITH CHECK (true);

-- ══════════════════════════════════════════
-- 17. CUSTOMER BILL VISIBILITY
-- ══════════════════════════════════════════
CREATE TABLE public.customer_bill_visibility (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  shop_id UUID NOT NULL REFERENCES public.shops(id),
  customer_id UUID NOT NULL REFERENCES public.customers(id),
  show_udhaar BOOLEAN DEFAULT TRUE,
  show_paid_bills BOOLEAN DEFAULT TRUE,
  show_balance BOOLEAN DEFAULT TRUE,
  updated_by UUID REFERENCES auth.users(id),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(shop_id, customer_id)
);
ALTER TABLE public.customer_bill_visibility ENABLE ROW LEVEL SECURITY;
CREATE POLICY "cbv_access" ON public.customer_bill_visibility
  FOR ALL USING (public.is_shop_member(shop_id))
  WITH CHECK (public.is_shop_member(shop_id));

-- ══════════════════════════════════════════
-- 18. CUSTOMER BILL READS
-- ══════════════════════════════════════════
CREATE TABLE public.customer_bill_reads (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  customer_account_id UUID REFERENCES public.customer_accounts(id),
  sale_id UUID REFERENCES public.sales(id),
  first_read_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(customer_account_id, sale_id)
);
ALTER TABLE public.customer_bill_reads ENABLE ROW LEVEL SECURITY;
CREATE POLICY "cbr_public" ON public.customer_bill_reads
  FOR ALL USING (true) WITH CHECK (true);

-- ══════════════════════════════════════════
-- 19. AD EVENTS
-- ══════════════════════════════════════════
CREATE TABLE public.ad_events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id),
  user_type VARCHAR(20),
  ad_unit_id VARCHAR(100),
  ad_type VARCHAR(20),
  ad_position VARCHAR(50),
  event_type VARCHAR(20),
  screen_name VARCHAR(50),
  city VARCHAR(80),
  device_type VARCHAR(20),
  session_id VARCHAR(50),
  revenue_usd DECIMAL(10,6) DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
ALTER TABLE public.ad_events ENABLE ROW LEVEL SECURITY;
CREATE POLICY "ad_events_insert" ON public.ad_events
  FOR INSERT WITH CHECK (true);
CREATE POLICY "ad_events_select" ON public.ad_events
  FOR SELECT USING (user_id = auth.uid());

-- ══════════════════════════════════════════
-- 20. AUDIT LOGS
-- ══════════════════════════════════════════
CREATE TABLE public.audit_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  shop_id UUID NOT NULL REFERENCES public.shops(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id),
  action TEXT NOT NULL,
  table_name TEXT NOT NULL,
  record_id UUID,
  details JSONB,
  timestamp TIMESTAMPTZ DEFAULT NOW()
);
ALTER TABLE public.audit_logs ENABLE ROW LEVEL SECURITY;
CREATE POLICY "audit_access" ON public.audit_logs
  FOR ALL USING (public.is_shop_member(shop_id))
  WITH CHECK (public.is_shop_member(shop_id));

-- ══════════════════════════════════════════
-- 21. BACKUP LOGS
-- ══════════════════════════════════════════
CREATE TABLE public.backup_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  shop_id UUID NOT NULL REFERENCES public.shops(id) ON DELETE CASCADE,
  status VARCHAR(20)
    CHECK (status IN ('SUCCESS','FAILURE','IN_PROGRESS')),
  drive_file_id TEXT,
  drive_url TEXT,
  error_message TEXT,
  timestamp TIMESTAMPTZ DEFAULT NOW()
);
ALTER TABLE public.backup_logs ENABLE ROW LEVEL SECURITY;
CREATE POLICY "backup_access" ON public.backup_logs
  FOR ALL USING (public.is_shop_member(shop_id))
  WITH CHECK (public.is_shop_member(shop_id));

-- ══════════════════════════════════════════
-- DONE! All 21 tables created successfully.
-- ══════════════════════════════════════════
