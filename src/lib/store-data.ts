import heroImage from "@/assets/corres-hero.jpg";
import storyImage from "@/assets/corres-story.jpg";

export const categories = ["Todos", "Camisetas", "Moletons", "Calças", "Bermudas", "Bonés", "Acessórios", "Drops"];

export const products = [
  { id: "camiseta-processo-oversized", slug: "camiseta-processo-oversized", name: "Camiseta Processo Oversized", category: "Camisetas", price: 149.9, compareAt: 179.9, image: heroImage, colors: ["Preto", "Branco"], sizes: ["P", "M", "G", "GG"], stock: 32, isDrop: true },
  { id: "moletom-disciplina-heavy", slug: "moletom-disciplina-heavy", name: "Moletom Disciplina Heavy", category: "Moletons", price: 289.9, image: storyImage, colors: ["Cinza Chumbo", "Preto"], sizes: ["P", "M", "G", "GG"], stock: 20, isDrop: false },
  { id: "bermuda-movimento-cargo", slug: "bermuda-movimento-cargo", name: "Bermuda Movimento Cargo", category: "Bermudas", price: 189.9, image: storyImage, colors: ["Preto"], sizes: ["P", "M", "G", "GG"], stock: 24, isDrop: false },
  { id: "bone-corre-6-panel", slug: "bone-corre-6-panel", name: "Boné Corre 6 Panel", category: "Bonés", price: 109.9, image: heroImage, colors: ["Preto"], sizes: ["Único"], stock: 12, isDrop: false },
];

export type StoreProduct = (typeof products)[number];
export const money = (value: number) => new Intl.NumberFormat("pt-BR", { style: "currency", currency: "BRL" }).format(value);