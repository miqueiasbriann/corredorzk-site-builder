<!-- LOVABLE:BEGIN -->
> [!IMPORTANT]
> This project is connected to [Lovable](https://lovable.dev). Avoid rewriting
> published git history — force pushing, or rebasing/amending/squashing commits
> that are already pushed — as it rewrites history on Lovable's side and the
> user will likely lose their project history.
>
> Commits you push to the connected branch sync back to Lovable and show up in
> the editor, so keep the branch in a working state.
<!-- LOVABLE:END -->

- Public commerce pages use curated local campaign assets and demo catalog data while Lovable Cloud remains the source of truth for editable admin data; this keeps the first official storefront fast and usable before final merchandise photography is supplied.
- Guest carts persist in browser storage, while finalized checkout records are written server-side before opening WhatsApp; this minimizes checkout friction without exposing customer records.
- Administrative access is gated by Cloud Auth and a separate `user_roles` table; this prevents self-registered users from gaining store privileges.
