import { createServerFn } from "@tanstack/react-start";
import { requireSupabaseAuth } from "@/integrations/supabase/auth-middleware";

export const getAdminDashboard = createServerFn({ method: "GET" }).middleware([requireSupabaseAuth]).handler(async ({ context }) => {
  const { data: role } = await context.supabase.from("user_roles").select("role").eq("user_id", context.userId).eq("role", "admin").maybeSingle();
  if (!role) throw new Error("Acesso restrito a administradores.");
  const [products, orders, customers, coupons] = await Promise.all([
    context.supabase.from("products").select("id,name,price,is_published,is_featured", { count: "exact" }).order("created_at", { ascending: false }),
    context.supabase.from("orders").select("id,order_number,status,total,created_at", { count: "exact" }).order("created_at", { ascending: false }).limit(8),
    context.supabase.from("customers").select("id", { count: "exact", head: true }),
    context.supabase.from("coupons").select("id", { count: "exact", head: true }),
  ]);
  return { products: products.data ?? [], productCount: products.count ?? 0, orders: orders.data ?? [], orderCount: orders.count ?? 0, customerCount: customers.count ?? 0, couponCount: coupons.count ?? 0 };
});