import { Link } from "@tanstack/react-router";
import { Instagram, Menu, Search, ShoppingBag, X } from "lucide-react";
import { useState, type ReactNode } from "react";
import { Button } from "@/components/ui/button";
import { useCart } from "@/lib/cart";

const nav = [{ label: "Início", to: "/" as const }, { label: "Loja", to: "/catalogo" as const }, { label: "Drops", to: "/catalogo" as const }];
export function Wordmark() { return <span className="brand-wordmark">CORRES<span>DO</span>ZK</span>; }

export function StoreShell({ children }: { children: ReactNode }) {
  const [open, setOpen] = useState(false);
  const { count } = useCart();
  return <div className="min-h-screen bg-background text-foreground">
    <div className="bg-primary px-4 py-2 text-center text-[10px] font-black uppercase tracking-[0.22em] text-primary-foreground">NÃO É SORTE. É PROCESSO.</div>
    <header className="sticky top-0 z-40 border-b border-border/70 bg-background/95 backdrop-blur">
      <div className="mx-auto flex h-18 max-w-7xl items-center justify-between px-4 lg:px-8">
        <Button variant="ghost" size="icon" className="lg:hidden" aria-label="Abrir menu" onClick={() => setOpen(!open)}>{open ? <X /> : <Menu />}</Button>
        <Link to="/" aria-label="CORRES DO ZK"><Wordmark /></Link>
        <nav className="hidden items-center gap-8 lg:flex">{nav.map((item) => <Link key={item.label} to={item.to} search={item.label === "Drops" ? { categoria: "Drops" } : undefined} className="text-xs font-bold uppercase tracking-[0.16em] text-muted-foreground transition-colors hover:text-foreground">{item.label}</Link>)}</nav>
        <div className="flex items-center gap-1"><Button variant="ghost" size="icon" aria-label="Buscar"><Search /></Button><Button variant="ghost" size="icon" asChild><Link to="/carrinho" aria-label={`Carrinho com ${count} itens`}><ShoppingBag /><span className="absolute mt-[-24px] ml-[24px] flex size-4 items-center justify-center rounded-full bg-primary text-[9px] text-primary-foreground">{count}</span></Link></Button></div>
      </div>
      {open && <nav className="grid border-t border-border bg-background p-4 lg:hidden">{nav.map((item) => <Link key={item.label} to={item.to} search={item.label === "Drops" ? { categoria: "Drops" } : undefined} onClick={() => setOpen(false)} className="border-b border-border py-4 text-lg font-black uppercase">{item.label}</Link>)}</nav>}
    </header>
    <main>{children}</main>
    <footer className="border-t border-border bg-surface px-4 py-12 lg:px-8"><div className="mx-auto grid max-w-7xl gap-10 md:grid-cols-3"><div><Wordmark /><p className="mt-4 max-w-xs text-sm text-muted-foreground">Streetwear para quem entende que toda conquista começa no processo.</p></div><div><p className="footer-title">NAVEGUE</p><div className="mt-4 grid gap-2 text-sm"><Link to="/catalogo">Coleção</Link><Link to="/carrinho">Carrinho</Link><Link to="/auth">Acesso administrativo</Link></div></div><div><p className="footer-title">ACOMPANHE O CORRE</p><a className="mt-4 inline-flex items-center gap-2 text-sm text-muted-foreground" href="#social"><Instagram className="size-4" /> Instagram em configuração</a></div></div><div className="mx-auto mt-12 flex max-w-7xl justify-between border-t border-border pt-6 text-[10px] uppercase text-muted-foreground"><span>© 2026 CORRES DO ZK</span><span>Feito no processo.</span></div></footer>
  </div>;
}