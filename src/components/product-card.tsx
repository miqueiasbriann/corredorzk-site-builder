import { Link } from "@tanstack/react-router";
import type { StoreProduct } from "@/lib/store-data";
import { money } from "@/lib/store-data";

export function ProductCard({ product }: { product: StoreProduct }) {
  return <Link to="/produto/$slug" params={{ slug: product.slug }} className="group block">
    <div className="relative aspect-[4/5] overflow-hidden bg-muted"><img src={product.image} alt={product.name} width={720} height={900} loading="lazy" className="h-full w-full object-cover transition-transform duration-700 group-hover:scale-105" />{product.isDrop && <span className="absolute left-3 top-3 bg-primary px-2 py-1 text-[10px] font-black uppercase text-primary-foreground">Drop</span>}</div>
    <div className="pt-4"><p className="text-[10px] font-bold uppercase tracking-[0.16em] text-muted-foreground">{product.category}</p><h3 className="mt-1 font-black uppercase">{product.name}</h3><div className="mt-2 flex gap-2 text-sm"><strong>{money(product.price)}</strong>{product.compareAt && <span className="text-muted-foreground line-through">{money(product.compareAt)}</span>}</div></div>
  </Link>;
}