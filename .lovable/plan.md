# Primeira versão oficial — CORRES DO ZK

## Objetivo
Criar uma loja streetwear premium, com experiência pública completa, compra finalizada pelo WhatsApp e uma área administrativa privada para manter conteúdo, catálogo, estoque, cupons, pedidos e configurações.

## Direção visual
- Identidade urbana premium em preto, branco, vermelho e cinza escuro.
- Conceito central: “NÃO É SORTE. É PROCESSO.”
- Experiência pensada primeiro para celular, com tipografia forte, fotografia de moda em destaque e movimentos discretos.
- Como a referência visual não está disponível nos arquivos atuais, seguirei fielmente a paleta e o conceito descritos, sem inventar dados comerciais.

## Entregas
1. **Base visual e navegação**
   - Cabeçalho adaptável, menu mobile, busca, acesso ao carrinho e rodapé.
   - Páginas separadas para início, catálogo, produto, carrinho, checkout e acesso administrativo.

2. **Loja pública**
   - Home com campanha principal, lançamentos, categorias, manifesto da marca e redes sociais.
   - Catálogo com filtros por categoria, tamanho, cor e faixa de preço.
   - Produto com galeria, preço normal/promocional, seleção de cor e tamanho, estoque e guia de medidas.
   - Carrinho persistente no navegador com quantidade, exclusão, subtotal e cupom.
   - Checkout com dados do cliente e endereço, criação do pedido e mensagem detalhada para WhatsApp.

3. **Administração segura**
   - Login separado e área `/admin` protegida por conta e função de administrador.
   - Visão geral de vendas/pedidos e telas para produtos, categorias, imagens, variações, estoque, cupons, pedidos e configurações.
   - Upload de imagens e edição dos textos/imagens principais da home.

4. **Dados e preparação para pagamentos**
   - Estrutura para categorias, produtos, mídia, variações, estoque, cupons, clientes, pedidos, itens, WhatsApps e configurações.
   - Status de pedido e campos preparados para Pix/cartão, sem ativar cobrança nesta etapa.
   - Regras de segurança: catálogo publicado visível ao público; dados de clientes e pedidos restritos; alterações somente por administradores.

5. **Validação**
   - Conferir fluxos principais em celular e desktop: navegação, filtros, produto, carrinho, cupom, checkout e acesso ao admin.
   - Revisar erros visuais, funcionamento e regras de segurança do banco.

## Dados iniciais e limites
- Serão usados produtos demonstrativos claramente editáveis para que a loja não abra vazia.
- Número de WhatsApp, redes sociais, preços, estoque e conteúdo definitivo continuarão editáveis no admin.
- O envio ao WhatsApp será funcional após cadastrar o número oficial nas configurações.
- Pix e cartão ficarão somente preparados; ativar pagamentos exigirá escolher e configurar um provedor em uma etapa futura.
- O primeiro administrador precisará ser vinculado a uma conta real antes de acessar o painel; nenhuma pessoa comum receberá permissão administrativa automaticamente.

## Detalhes técnicos
- Frontend em TanStack Start, seguindo a estrutura existente.
- Lovable Cloud para banco, autenticação e armazenamento de imagens.
- Carrinho local para compra sem cadastro; pedido persistido no envio ao WhatsApp.
- Controle de acesso por função em tabela separada e validação no servidor/banco.
