# Ocorrência dos padrões Prototype, Adapter e Observer no projeto Nevernote

Durante o desenvolvimento do projeto Nevernote, uma aplicação inspirada no Evernote desenvolvida em Angular, foram utilizados os padrões de projeto **Prototype**, **Adapter** e **Observer**. A adoção desses padrões teve como objetivo aumentar a modularidade, a reutilização de código e facilitar a manutenção do sistema.

---

## Padrão Prototype

O padrão **Prototype** foi aplicado na entidade `Note`, responsável por representar uma nota do sistema. Sua principal finalidade é permitir a criação de novos objetos a partir da clonagem de objetos já existentes, evitando a necessidade de construir um novo objeto manualmente.

Essa implementação pode ser observada no método `clone()` presente em `makeNote()`.

```typescript
export interface Note extends NoteData, Prototype {}

clone(): Note {
  const now = new Date();

  return {
    ...this,
    id: generateId(),
    title: `${fields.title} (copy)`,
    createdAt: now,
    updatedAt: now,

    reminderAt: undefined,
    pinned: false,
  };
}
```

Além disso, o método é utilizado na lista de notas:

```typescript
onCopy(note: Note) {
  this
    .noteRepo
    .create(note.clone() as Note)
}
```

Quando o usuário solicita a duplicação de uma nota, o sistema não cria uma nova nota do zero. Em vez disso, utiliza a nota existente como modelo, gerando uma cópia com um novo identificador, novas datas de criação e atualização e alguns atributos redefinidos, como `pinned`.

A utilização do Prototype é adequada nesse cenário porque as notas possuem diversos atributos e a sua reconstrução manual seria redundante e sujeita a erros. Dessa forma, a clonagem torna o processo mais simples, reduz a duplicação de código e facilita a manutenção futura.

---

## Padrão Adapter

O padrão **Adapter** foi implementado na classe `TiptapAdapter`, cuja função é adaptar a biblioteca externa TipTap à interface interna utilizada pelo Nevernote.

A classe é declarada da seguinte forma:

```typescript
export class TiptapAdapter implements EditorAdapter
```

Ela recebe um objeto do tipo `Editor`, pertencente à biblioteca TipTap, e converte seus métodos para a interface esperada pela aplicação.

Exemplos:

```typescript
mount(element: ElementRef<HTMLElement>) {
  this.tiptap.mount(element.nativeElement);
  return this;
}

destroy() {
  this.tiptap.unmount();
  this.tiptap.destroy();
  return this;
}

getHTML() {
  return this.tiptap.getHTML();
}

setEditable(editable: boolean) {
  this.tiptap.setEditable(editable);
  return this;
}
```

O objetivo desse padrão é desacoplar a aplicação da biblioteca externa. O restante do Nevernote não precisa conhecer a implementação específica do TipTap, mas apenas a interface `EditorAdapter`.

Essa abordagem traz diversas vantagens. Caso seja necessário substituir o TipTap por outro editor de texto no futuro, a maior parte do código permanecerá inalterada. Apenas um novo adaptador precisará ser criado, implementando a mesma interface.

Portanto, o Adapter atua como um intermediário entre duas interfaces incompatíveis: a interface fornecida pela biblioteca TipTap e a interface utilizada internamente pelo Nevernote.

---

## Padrão Observer

O padrão **Observer** aparece no sistema por meio dos mecanismos reativos do Angular, principalmente através dos `signals` e das inscrições (`subscribe`) realizadas sobre eventos e observables.

Um exemplo ocorre na funcionalidade de exclusão de notas:

```typescript
onTrash(note: Note) {
  this
    .trasher
    .trash(note.id)
    .subscribe(n => this.noteStore.remove(n.id));
}
```

Outro exemplo ocorre na atualização do estado de uma nota:

```typescript
onPinToggle(note: Note) {
  this
    .noteRepo
    .update(note.id, { pinned: !note.pinned })
    .subscribe(n => this.noteStore.update(n));
}
```

Também aparece na duplicação:

```typescript
onCopy(note: Note) {
  this
    .noteRepo
    .create(note.clone() as Note)
    .pipe(
      tap(n => this.noteStore.add(n))
    )
    .subscribe(...)
}
```

Além disso, o padrão está presente dentro do `TiptapAdapter`:

```typescript
this.tiptap.on('update', ({ editor }) => {
  this.words.set(editor.storage.characterCount.words());
})
```

Nesse caso, o editor TipTap atua como o objeto observável (*Subject*), enquanto a função registrada em `on('update')` atua como observadora (*Observer*). Sempre que o conteúdo do editor é alterado, o evento é disparado automaticamente e a quantidade de palavras é atualizada.

De forma geral, a lógica do Observer consiste em estabelecer uma relação de dependência entre objetos, de modo que, quando um objeto sofre uma alteração de estado, todos os observadores registrados sejam notificados automaticamente.

A utilização desse padrão é especialmente importante em aplicações Angular, pois permite que a interface permaneça sincronizada com os dados sem a necessidade de verificações manuais constantes. Isso torna o código mais organizado, reativo e de fácil manutenção.
