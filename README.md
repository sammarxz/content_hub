# ContentHub

ContentHub é uma aplicação web construída com Phoenix LiveView para geração e gerenciamento de links UTM, QR codes e pré-visualização de meta tags.

## Visão do Projeto

Facilitar o trabalho de profissionais de marketing e desenvolvedores na criação e gerenciamento de links UTM para campanhas, oferecendo uma interface intuitiva e dinâmica com feedback visual em tempo real.

## Funcionalidades Planejadas

### Fase 1: Estrutura Base e UTM Builder
- [x] Setup inicial do projeto Phoenix
- [x] Implementação do formulário de UTM
- [x] Geração de links UTM
- [x] Copiar link para clipboard
- [x] Preview em tempo real dos links gerados

### Fase 2: Meta Preview
- [ ] Busca de metadados de URLs (og:title, og:description, og:image)
- [ ] Preview visual do card social
- [ ] Cache de metadados
- [ ] Tratamento de erros de requisição
- [ ] Loading states

### Fase 3: QR Code
- [ ] Geração de QR code para links
- [ ] Customização de QR code (cores, tamanho)
- [ ] Download do QR code
- [ ] Preview em tempo real

### Fase 4: Histórico e Analytics
- [ ] Salvar histórico de links no localStorage
- [ ] Listagem de links recentes
- [ ] Exportação do histórico em JSON
- [ ] Limpeza de histórico

## Tecnologias

- Elixir 1.15
- Phoenix 1.7
- Phoenix LiveView
- TailwindCSS
- Local Storage para persistência de dados

## Setup do Projeto

```bash
# Clone o repositório
git clone https://github.com/seu-usuario/content_hub
cd content_hub

# Instale as dependências
mix deps.get
mix deps.compile

# Crie e migre o banco de dados
mix ecto.setup

# Instale as dependências do Node.js
cd assets && npm install

# Inicie o servidor Phoenix
mix phx.server
```

Agora você pode visitar [`localhost:4000`](http://localhost:4000) do seu navegador.

## Desenvolvimento

### Commits

Seguimos o padrão de Commits Convencionais:
- `feat`: Nova funcionalidade
- `fix`: Correção de bug
- `docs`: Alteração em documentação
- `style`: Formatação, ponto e vírgula faltando, etc
- `refactor`: Refatoração de código
- `test`: Adição ou correção de testes
- `chore`: Atualização de tarefas de build, configurações, etc

### Estrutura de Branches

- `main`: Código em produção
- `develop`: Branch principal de desenvolvimento
- `feature/*`: Novas funcionalidades
- `fix/*`: Correções de bugs
- `release/*`: Preparação para release

## Testes

```bash
# Rodar todos os testes
mix test

# Rodar testes com cobertura
mix test --cover
```

## Contribuindo

1. Fork o projeto
2. Crie sua branch (`git checkout -b feature/amazing-feature`)
3. Commit suas mudanças (`git commit -m 'feat: add amazing feature'`)
4. Push para a branch (`git push origin feature/amazing-feature`)
5. Abra um Pull Request

## Licença

Este projeto está sob a licença MIT - veja o arquivo [LICENSE.md](LICENSE.md) para detalhes.