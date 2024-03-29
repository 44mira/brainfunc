# Brainf\*ck Interpreter in Elixir.

Wanted to try my hand at parsing a language. Imperatively, Brainf\*ck is trivial to interpret,
which is why I wanted to try it in a functional language like Elixir.

Learned and applied the different steps of interpreting/parsing a language, such as lexing and evaluation.

> Documentation HTML and epub inside `brainfunc/doc`.

## Examples

Linux

```
  $> ./bfi hello.txt
  Hello world!
  $> ./bfi --eval --size=10 "++++++[>+++++++++<-]>.+++."
  69
```

Windows

```
  $> escript bfi hello.txt
  Hello world!
  $> escript bfi --eval --size=10 "++++++[>+++++++++<-]>.+++."
  69
```
