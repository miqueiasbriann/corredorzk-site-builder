import { createServerFn } from "@tanstack/react-start";
import { z } from "zod";

const checkoutSchema = z.object({
  customer: z.object({ name: z.string().min(2).max(120), phone: z.string().min(8).max(30), email: z.string().email().optional().or(z.literal("")), postalCode: z.string().min(5).max(12), street: z.string().min(2).max(180), number: z.string().min(1).max(20), complement: z.string().max(100).optional(), neighborhood: z.string().min(2).max(100), city: z.string().min(2).max(100), state: z.string().min(2).max(2) }),
  items: z.array(z.object({ productId: z.string().min(1), name: z.string().min(1).max(160), sku: z.string().max(80), color: z.string().max(80), size: z.string().max(20), quantity: z.number().int().min(1).max(20), unitPrice: z.number().nonnegative() })).min(1).max(30),
  couponCode: z.string().max(40).optional(), notes: z.string().max(500).optional(),
});

export const createWhatsAppOrder = createServerFn({ method: "POST" }).inputValidator((input) => checkoutSchema.parse(input)).handler(async ({ data }) => {
  const { supabaseAdmin } = await import("@/integrations/supabase/client.server");
  const subtotal = data.items.reduce((sum, item) => sum + item.unitPrice * item.quantity, 0);
  let discount = 0;
  if (data.couponCode) {
    const { data: coupon } = await supabaseAdmin.from("coupons").select("*").eq("code", data.couponCode.toUpperCase()).eq("is_active", true).maybeSingle();
    if (coupon && subtotal >= Number(coupon.minimum_order)) discount = coupon.discount_type === "percentage" ? subtotal * Number(coupon.discount_value) / 100 : Number(coupon.discount_value);
  }
  const total = Math.max(0, subtotal - discount);
  const { data: customer, error: customerError } = await supabaseAdmin.from("customers").insert({ name: data.customer.name, phone: data.customer.phone, email: data.customer.email || null, postal_code: data.customer.postalCode, street: data.customer.street, number: data.customer.number, complement: data.customer.complement || null, neighborhood: data.customer.neighborhood, city: data.customer.city, state: data.customer.state.toUpperCase() }).select("id").single();
  if (customerError || !customer) throw new Error("Não foi possível registrar seus dados.");
  const orderNumber = `CDZ-${Date.now().toString().slice(-8)}`;
  const address = { postalCode: data.customer.postalCode, street: data.customer.street, number: data.customer.number, complement: data.customer.complement, neighborhood: data.customer.neighborhood, city: data.customer.city, state: data.customer.state.toUpperCase() };
  const lines = data.items.map((item) => `• ${item.quantity}x ${item.name} — ${item.color} / ${item.size} — R$ ${(item.unitPrice * item.quantity).toFixed(2).replace(".", ",")}`);
  const message = [`Olá! Quero finalizar o pedido *${orderNumber}*`, "", ...lines, "", `Subtotal: R$ ${subtotal.toFixed(2).replace(".", ",")}`, discount ? `Desconto: R$ ${discount.toFixed(2).replace(".", ",")}` : "", `*Total: R$ ${total.toFixed(2).replace(".", ")}*`, "", `Cliente: ${data.customer.name}`, `Telefone: ${data.customer.phone}`, `Entrega: ${data.customer.street}, ${data.customer.number}${data.customer.complement ? `, ${data.customer.complement}` : ""} — ${data.customer.neighborhood}, ${data.customer.city}/${data.customer.state.toUpperCase()} — CEP ${data.customer.postalCode}`, data.notes ? `Observações: ${data.notes}` : ""].filter(Boolean).join("\n");
  const { data: order, error: orderError } = await supabaseAdmin.from("orders").insert({ customer_id: customer.id, order_number: orderNumber, subtotal, discount, total, coupon_code: data.couponCode?.toUpperCase() || null, notes: data.notes || null, address_snapshot: address, whatsapp_message: message }).select("id").single();
  if (orderError || !order) throw new Error("Não foi possível criar o pedido.");
  const { error: itemsError } = await supabaseAdmin.from("order_items").insert(data.items.map((item) => ({ order_id: order.id, product_id: null, variant_id: null, product_name: item.name, sku: item.sku, color_name: item.color, size: item.size, quantity: item.quantity, unit_price: item.unitPrice, total_price: item.unitPrice * item.quantity })));
  if (itemsError) throw new Error("Não foi possível registrar os itens.");
  const { data: settings } = await supabaseAdmin.from("store_settings").select("whatsapp_number").limit(1).maybeSingle();
  return { orderNumber, message, whatsappNumber: settings?.whatsapp_number ?? "", total };
});