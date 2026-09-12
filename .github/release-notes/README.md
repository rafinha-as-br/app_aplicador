# Notas de release

Um arquivo por componente e versão, no formato:

```
.github/release-notes/<componente>-<versao>.md
```

Exemplo: `.github/release-notes/geoprag_aplicador-1.1.0.md`

O `release.yml` procura esse arquivo ao criar a GitHub Release e o usa
como corpo (`gh release create --notes-file`).

## Ordem de busca

```text
1. .github/release-notes/<componente>-<versao>.md
2. .github/release-notes/<componente>-<versao-base>.md
3. --generate-notes do GitHub
```

A **versão base** é a versão sem o identificador de pre-release:
`1.4.0-rc.2` → `1.4.0`. Por causa disso, um único arquivo
`geoprag_aplicador-1.4.0.md` serve o `rc.1`, o `rc.2` e a versão final —
que é o que se quer, já que as três descrevem a mesma entrega. Um arquivo
específico de rc só precisa existir quando houver algo a dizer **só**
daquele rc.

> ⚠️ A GitHub Release só é criada em release **final** — uma pre-release
> gera tag e artefato, sem Release. O arquivo de notas continua sendo
> escrito no momento do rc, porque é ele que vai ser usado quando aquela
> versão for promovida.

## Como escrever

Quem normalmente escreve esses arquivos é a skill `jira-release-executor`,
a partir do campo `Resumo` das issues incluídas na release. O commit
acontece antes do dispatch, para que o arquivo esteja presente no código
que a Action vai buildar.

**O texto é para qualquer pessoa ler** — inclusive quem não acompanhou a
sprint e não vai abrir Pull Request nenhum.

- Descreva o que mudou **do ponto de vista de quem usa o sistema**, não do
  ponto de vista do código.
- Não liste issues ou PRs como se fossem o conteúdo. Se citar uma issue,
  que seja no fim, como referência — nunca no lugar da explicação.
- Agrupe por tema, não por issue.
- Nada de mensagem de commit, nome de branch, nome de arquivo ou termo
  interno que só faça sentido para quem desenvolveu.
