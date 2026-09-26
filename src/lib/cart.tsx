import { createContext, useContext, useEffect, useMemo, useState, type ReactNode } from "react";
import type { StoreProduct } from "./store-data";

export type CartItem = { product: StoreProduct; color: string; size: string; quantity: number };
type CartValue = { items: CartItem[]; count: number; subtotal: number; add: (item: CartItem) => void; update: (id: string, color: string, size: string, quantity: number) => void; remove: (id: string, color: string, size: string) => void; clear: () => void };
const CartContext = createContext<CartValue | null>(null);

export function CartProvider({ children }: { children: ReactNode }) {
  const [items, setItems] = useState<CartItem[]>([]);
  useEffect(() => { try { const saved = localStorage.getItem("corres-cart"); if (saved) setItems(JSON.parse(saved)); } catch {} }, []);
  useEffect(() => { localStorage.setItem("corres-cart", JSON.stringify(items)); }, [items]);
  const value = useMemo<CartValue>(() => ({
    items,
    count: items.reduce((sum, item) => sum + item.quantity, 0),
    subtotal: items.reduce((sum, item) => sum + item.product.price * item.quantity, 0),
    add: (next) => setItems((current) => { const found = current.find((item) => item.product.id === next.product.id && item.color === next.color && item.size === next.size); return found ? current.map((item) => item === found ? { ...item, quantity: item.quantity + next.quantity } : item) : [...current, next]; }),
    update: (id, color, size, quantity) => setItems((current) => current.map((item) => item.product.id === id && item.color === color && item.size === size ? { ...item, quantity: Math.max(1, quantity) } : item)),
    remove: (id, color, size) => setItems((current) => current.filter((item) => !(item.product.id === id && item.color === color && item.size === size))),
    clear: () => setItems([]),
  }), [items]);
  return <CartContext.Provider value={value}>{children}</CartContext.Provider>;
}

export function useCart() { const value = useContext(CartContext); if (!value) throw new Error("CartProvider ausente"); return value; }