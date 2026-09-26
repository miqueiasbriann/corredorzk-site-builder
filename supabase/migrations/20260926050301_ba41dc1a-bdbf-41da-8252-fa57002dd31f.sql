CREATE TYPE public.app_role AS ENUM ('admin', 'staff');
CREATE TYPE public.order_status AS ENUM ('pending', 'confirmed', 'preparing', 'shipped', 'completed', 'cancelled');
CREATE TYPE public.payment_status AS ENUM ('pending', 'authorized', 'paid', 'failed', 'refunded');
CREATE TYPE public.discount_type AS ENUM ('percentage', 'fixed');

CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS trigger LANGUAGE plpgsql SET search_path = public AS $$
BEGIN NEW.updated_at = now(); RETURN NEW; END;
$$;

CREATE TABLE public.user_roles (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL,
  role public.app_role NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (user_id, role)
);
GRANT SELECT ON public.user_roles TO authenticated;
GRANT ALL ON public.user_roles TO service_role;
ALTER TABLE public.user_roles ENABLE ROW LEVEL SECURITY;

CREATE OR REPLACE FUNCTION public.has_role(_user_id uuid, _role public.app_role)
RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT EXISTS (SELECT 1 FROM public.user_roles WHERE user_id = _user_id AND role = _role)
$$;
GRANT EXECUTE ON FUNCTION public.has_role(uuid, public.app_role) TO authenticated;

CREATE POLICY "Users read own roles" ON public.user_roles FOR SELECT TO authenticated USING (user_id = auth.uid());
CREATE POLICY "Admins manage roles" ON public.user_roles FOR ALL TO authenticated USING (public.has_role(auth.uid(), 'admin')) WITH CHECK (public.has_role(auth.uid(), 'admin'));

CREATE TABLE public.categories (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL UNIQUE,
  slug text NOT NULL UNIQUE,
  description text,
  image_url text,
  sort_order integer NOT NULL DEFAULT 0,
  is_active boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
GRANT SELECT ON public.categories TO anon, authenticated;
GRANT INSERT, UPDATE, DELETE ON public.categories TO authenticated;
GRANT ALL ON public.categories TO service_role;
ALTER TABLE public.categories ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Public reads active categories" ON public.categories FOR SELECT TO anon, authenticated USING (is_active OR public.has_role(auth.uid(), 'admin'));
CREATE POLICY "Admins manage categories" ON public.categories FOR ALL TO authenticated USING (public.has_role(auth.uid(), 'admin')) WITH CHECK (public.has_role(auth.uid(), 'admin'));
CREATE TRIGGER categories_updated BEFORE UPDATE ON public.categories FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TABLE public.products (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  category_id uuid REFERENCES public.categories(id) ON DELETE SET NULL,
  name text NOT NULL,
  slug text NOT NULL UNIQUE,
  short_description text,
  description text,
  price numeric(12,2) NOT NULL CHECK (price >= 0),
  compare_at_price numeric(12,2) CHECK (compare_at_price IS NULL OR compare_at_price >= price),
  is_published boolean NOT NULL DEFAULT false,
  is_featured boolean NOT NULL DEFAULT false,
  is_drop boolean NOT NULL DEFAULT false,
  size_guide jsonb NOT NULL DEFAULT '[]'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
GRANT SELECT ON public.products TO anon, authenticated;
GRANT INSERT, UPDATE, DELETE ON public.products TO authenticated;
GRANT ALL ON public.products TO service_role;
ALTER TABLE public.products ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Public reads published products" ON public.products FOR SELECT TO anon, authenticated USING (is_published OR public.has_role(auth.uid(), 'admin'));
CREATE POLICY "Admins manage products" ON public.products FOR ALL TO authenticated USING (public.has_role(auth.uid(), 'admin')) WITH CHECK (public.has_role(auth.uid(), 'admin'));
CREATE TRIGGER products_updated BEFORE UPDATE ON public.products FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TABLE public.product_images (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  product_id uuid NOT NULL REFERENCES public.products(id) ON DELETE CASCADE,
  url text NOT NULL,
  alt_text text,
  sort_order integer NOT NULL DEFAULT 0,
  is_primary boolean NOT NULL DEFAULT false,
  created_at timestamptz NOT NULL DEFAULT now()
);
GRANT SELECT ON public.product_images TO anon, authenticated;
GRANT INSERT, UPDATE, DELETE ON public.product_images TO authenticated;
GRANT ALL ON public.product_images TO service_role;
ALTER TABLE public.product_images ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Public reads product images" ON public.product_images FOR SELECT TO anon, authenticated USING (EXISTS (SELECT 1 FROM public.products p WHERE p.id = product_id AND (p.is_published OR public.has_role(auth.uid(), 'admin'))));
CREATE POLICY "Admins manage product images" ON public.product_images FOR ALL TO authenticated USING (public.has_role(auth.uid(), 'admin')) WITH CHECK (public.has_role(auth.uid(), 'admin'));

CREATE TABLE public.product_variants (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  product_id uuid NOT NULL REFERENCES public.products(id) ON DELETE CASCADE,
  sku text NOT NULL UNIQUE,
  color_name text NOT NULL,
  color_hex text NOT NULL DEFAULT '#111111',
  size text NOT NULL,
  stock integer NOT NULL DEFAULT 0 CHECK (stock >= 0),
  is_active boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE(product_id, color_name, size)
);
GRANT SELECT ON public.product_variants TO anon, authenticated;
GRANT INSERT, UPDATE, DELETE ON public.product_variants TO authenticated;
GRANT ALL ON public.product_variants TO service_role;
ALTER TABLE public.product_variants ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Public reads active variants" ON public.product_variants FOR SELECT TO anon, authenticated USING ((is_active AND EXISTS (SELECT 1 FROM public.products p WHERE p.id = product_id AND p.is_published)) OR public.has_role(auth.uid(), 'admin'));
CREATE POLICY "Admins manage product variants" ON public.product_variants FOR ALL TO authenticated USING (public.has_role(auth.uid(), 'admin')) WITH CHECK (public.has_role(auth.uid(), 'admin'));
CREATE TRIGGER product_variants_updated BEFORE UPDATE ON public.product_variants FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TABLE public.coupons (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  code text NOT NULL UNIQUE,
  discount_type public.discount_type NOT NULL,
  discount_value numeric(12,2) NOT NULL CHECK (discount_value > 0),
  minimum_order numeric(12,2) NOT NULL DEFAULT 0,
  usage_limit integer,
  used_count integer NOT NULL DEFAULT 0,
  starts_at timestamptz,
  ends_at timestamptz,
  is_active boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
GRANT SELECT, INSERT, UPDATE, DELETE ON public.coupons TO authenticated;
GRANT ALL ON public.coupons TO service_role;
ALTER TABLE public.coupons ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Admins manage coupons" ON public.coupons FOR ALL TO authenticated USING (public.has_role(auth.uid(), 'admin')) WITH CHECK (public.has_role(auth.uid(), 'admin'));
CREATE TRIGGER coupons_updated BEFORE UPDATE ON public.coupons FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TABLE public.customers (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  phone text NOT NULL,
  email text,
  postal_code text NOT NULL,
  street text NOT NULL,
  number text NOT NULL,
  complement text,
  neighborhood text NOT NULL,
  city text NOT NULL,
  state text NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
GRANT SELECT, INSERT, UPDATE, DELETE ON public.customers TO authenticated;
GRANT ALL ON public.customers TO service_role;
ALTER TABLE public.customers ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Admins manage customers" ON public.customers FOR ALL TO authenticated USING (public.has_role(auth.uid(), 'admin')) WITH CHECK (public.has_role(auth.uid(), 'admin'));
CREATE TRIGGER customers_updated BEFORE UPDATE ON public.customers FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TABLE public.orders (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  customer_id uuid NOT NULL REFERENCES public.customers(id),
  order_number text NOT NULL UNIQUE,
  status public.order_status NOT NULL DEFAULT 'pending',
  payment_method text NOT NULL DEFAULT 'whatsapp',
  payment_status public.payment_status NOT NULL DEFAULT 'pending',
  subtotal numeric(12,2) NOT NULL CHECK (subtotal >= 0),
  discount numeric(12,2) NOT NULL DEFAULT 0 CHECK (discount >= 0),
  total numeric(12,2) NOT NULL CHECK (total >= 0),
  coupon_code text,
  notes text,
  address_snapshot jsonb NOT NULL,
  whatsapp_message text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
GRANT SELECT, INSERT, UPDATE, DELETE ON public.orders TO authenticated;
GRANT ALL ON public.orders TO service_role;
ALTER TABLE public.orders ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Admins manage orders" ON public.orders FOR ALL TO authenticated USING (public.has_role(auth.uid(), 'admin')) WITH CHECK (public.has_role(auth.uid(), 'admin'));
CREATE TRIGGER orders_updated BEFORE UPDATE ON public.orders FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TABLE public.order_items (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id uuid NOT NULL REFERENCES public.orders(id) ON DELETE CASCADE,
  product_id uuid REFERENCES public.products(id) ON DELETE SET NULL,
  variant_id uuid REFERENCES public.product_variants(id) ON DELETE SET NULL,
  product_name text NOT NULL,
  sku text NOT NULL,
  color_name text NOT NULL,
  size text NOT NULL,
  quantity integer NOT NULL CHECK (quantity > 0),
  unit_price numeric(12,2) NOT NULL CHECK (unit_price >= 0),
  total_price numeric(12,2) NOT NULL CHECK (total_price >= 0),
  created_at timestamptz NOT NULL DEFAULT now()
);
GRANT SELECT, INSERT, UPDATE, DELETE ON public.order_items TO authenticated;
GRANT ALL ON public.order_items TO service_role;
ALTER TABLE public.order_items ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Admins manage order items" ON public.order_items FOR ALL TO authenticated USING (public.has_role(auth.uid(), 'admin')) WITH CHECK (public.has_role(auth.uid(), 'admin'));

CREATE TABLE public.site_content (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  section_key text NOT NULL UNIQUE,
  eyebrow text,
  title text NOT NULL,
  body text,
  image_url text,
  cta_label text,
  cta_url text,
  is_active boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
GRANT SELECT ON public.site_content TO anon, authenticated;
GRANT INSERT, UPDATE, DELETE ON public.site_content TO authenticated;
GRANT ALL ON public.site_content TO service_role;
ALTER TABLE public.site_content ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Public reads active site content" ON public.site_content FOR SELECT TO anon, authenticated USING (is_active OR public.has_role(auth.uid(), 'admin'));
CREATE POLICY "Admins manage site content" ON public.site_content FOR ALL TO authenticated USING (public.has_role(auth.uid(), 'admin')) WITH CHECK (public.has_role(auth.uid(), 'admin'));
CREATE TRIGGER site_content_updated BEFORE UPDATE ON public.site_content FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TABLE public.social_links (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  platform text NOT NULL,
  label text NOT NULL,
  url text NOT NULL,
  sort_order integer NOT NULL DEFAULT 0,
  is_active boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
GRANT SELECT ON public.social_links TO anon, authenticated;
GRANT INSERT, UPDATE, DELETE ON public.social_links TO authenticated;
GRANT ALL ON public.social_links TO service_role;
ALTER TABLE public.social_links ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Public reads active social links" ON public.social_links FOR SELECT TO anon, authenticated USING (is_active OR public.has_role(auth.uid(), 'admin'));
CREATE POLICY "Admins manage social links" ON public.social_links FOR ALL TO authenticated USING (public.has_role(auth.uid(), 'admin')) WITH CHECK (public.has_role(auth.uid(), 'admin'));
CREATE TRIGGER social_links_updated BEFORE UPDATE ON public.social_links FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TABLE public.store_settings (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  store_name text NOT NULL DEFAULT 'CORRES DO ZK',
  whatsapp_number text NOT NULL DEFAULT '',
  whatsapp_message_template text NOT NULL DEFAULT 'Olá! Quero finalizar meu pedido:',
  currency text NOT NULL DEFAULT 'BRL',
  instagram_url text,
  shipping_note text,
  pix_enabled boolean NOT NULL DEFAULT false,
  card_enabled boolean NOT NULL DEFAULT false,
  updated_at timestamptz NOT NULL DEFAULT now()
);
GRANT SELECT ON public.store_settings TO anon, authenticated;
GRANT INSERT, UPDATE, DELETE ON public.store_settings TO authenticated;
GRANT ALL ON public.store_settings TO service_role;
ALTER TABLE public.store_settings ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Public reads store contact settings" ON public.store_settings FOR SELECT TO anon, authenticated USING (true);
CREATE POLICY "Admins manage store settings" ON public.store_settings FOR ALL TO authenticated USING (public.has_role(auth.uid(), 'admin')) WITH CHECK (public.has_role(auth.uid(), 'admin'));
CREATE TRIGGER store_settings_updated BEFORE UPDATE ON public.store_settings FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE INDEX products_category_idx ON public.products(category_id);
CREATE INDEX products_published_idx ON public.products(is_published, is_featured);
CREATE INDEX variants_product_idx ON public.product_variants(product_id);
CREATE INDEX images_product_idx ON public.product_images(product_id, sort_order);
CREATE INDEX orders_status_created_idx ON public.orders(status, created_at DESC);
CREATE INDEX order_items_order_idx ON public.order_items(order_id);

INSERT INTO public.categories (name, slug, description, sort_order) VALUES
('Camisetas', 'camisetas', 'Camisetas streetwear para o corre diário.', 1),
('Moletons', 'moletons', 'Peso, conforto e presença para dias frios.', 2),
('Calças', 'calcas', 'Modelagens urbanas construídas para movimento.', 3),
('Bermudas', 'bermudas', 'Liberdade e resistência em cada passo.', 4),
('Bonés', 'bones', 'O acabamento certo para o uniforme da rua.', 5),
('Acessórios', 'acessorios', 'Detalhes que carregam identidade.', 6),
('Drops', 'drops', 'Edições limitadas. Quando acaba, virou história.', 7);

INSERT INTO public.products (category_id, name, slug, short_description, description, price, compare_at_price, is_published, is_featured, is_drop, size_guide)
SELECT id, 'Camiseta Processo Oversized', 'camiseta-processo-oversized', 'Algodão encorpado, modelagem ampla e assinatura frontal.', 'Peça demonstrativa da primeira coleção CORRES DO ZK. Conteúdo, preço e imagens podem ser atualizados no painel.', 149.90, 179.90, true, true, true, '[{"size":"P","chest":"54 cm","length":"70 cm"},{"size":"M","chest":"57 cm","length":"73 cm"},{"size":"G","chest":"60 cm","length":"76 cm"},{"size":"GG","chest":"63 cm","length":"79 cm"}]'::jsonb FROM public.categories WHERE slug = 'camisetas';
INSERT INTO public.products (category_id, name, slug, short_description, description, price, is_published, is_featured, size_guide)
SELECT id, 'Moletom Disciplina Heavy', 'moletom-disciplina-heavy', 'Moletom pesado com capuz estruturado e visual limpo.', 'Peça demonstrativa da primeira coleção CORRES DO ZK. Conteúdo, preço e imagens podem ser atualizados no painel.', 289.90, true, true, '[{"size":"P","chest":"58 cm","length":"68 cm"},{"size":"M","chest":"61 cm","length":"71 cm"},{"size":"G","chest":"64 cm","length":"74 cm"},{"size":"GG","chest":"67 cm","length":"77 cm"}]'::jsonb FROM public.categories WHERE slug = 'moletons';
INSERT INTO public.products (category_id, name, slug, short_description, description, price, is_published, is_featured)
SELECT id, 'Bermuda Movimento Cargo', 'bermuda-movimento-cargo', 'Estrutura utilitária e caimento confortável.', 'Peça demonstrativa da primeira coleção CORRES DO ZK. Conteúdo, preço e imagens podem ser atualizados no painel.', 189.90, true, true FROM public.categories WHERE slug = 'bermudas';
INSERT INTO public.products (category_id, name, slug, short_description, description, price, is_published, is_featured)
SELECT id, 'Boné Corre 6 Panel', 'bone-corre-6-panel', 'Construção clássica, bordado frontal e ajuste traseiro.', 'Peça demonstrativa da primeira coleção CORRES DO ZK. Conteúdo, preço e imagens podem ser atualizados no painel.', 109.90, true, true FROM public.categories WHERE slug = 'bones';

INSERT INTO public.product_variants (product_id, sku, color_name, color_hex, size, stock)
SELECT p.id, 'CDZ-CPO-PT-' || s.size, 'Preto', '#111111', s.size, 8 FROM public.products p CROSS JOIN (VALUES ('P'),('M'),('G'),('GG')) AS s(size) WHERE p.slug='camiseta-processo-oversized';
INSERT INTO public.product_variants (product_id, sku, color_name, color_hex, size, stock)
SELECT p.id, 'CDZ-MDH-CZ-' || s.size, 'Cinza Chumbo', '#343434', s.size, 5 FROM public.products p CROSS JOIN (VALUES ('P'),('M'),('G'),('GG')) AS s(size) WHERE p.slug='moletom-disciplina-heavy';
INSERT INTO public.product_variants (product_id, sku, color_name, color_hex, size, stock)
SELECT p.id, 'CDZ-BMC-PT-' || s.size, 'Preto', '#111111', s.size, 6 FROM public.products p CROSS JOIN (VALUES ('P'),('M'),('G'),('GG')) AS s(size) WHERE p.slug='bermuda-movimento-cargo';
INSERT INTO public.product_variants (product_id, sku, color_name, color_hex, size, stock)
SELECT p.id, 'CDZ-BC6-PT-U', 'Preto', '#111111', 'Único', 12 FROM public.products p WHERE p.slug='bone-corre-6-panel';

INSERT INTO public.site_content (section_key, eyebrow, title, body, cta_label, cta_url) VALUES
('hero', 'DROP 001', 'NÃO É SORTE. É PROCESSO.', 'Streetwear para quem transforma rotina em resultado. Vista o corre.', 'CONHECER O DROP', '/catalogo'),
('story', 'NOSSA HISTÓRIA', 'DA RUA. PARA QUEM FAZ ACONTECER.', 'CORRES DO ZK nasce do movimento, da disciplina e da certeza de que nenhuma conquista vem por acaso.', 'VER A COLEÇÃO', '/catalogo');
INSERT INTO public.store_settings (store_name, whatsapp_number, instagram_url, shipping_note) VALUES ('CORRES DO ZK', '', '', 'Frete calculado no atendimento pelo WhatsApp.');