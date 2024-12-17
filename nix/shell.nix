{ 
  mkShell,
  c3c,
}:
mkShell {
  buildInputs = [ 
    c3c
  ];

  shellHook = ''zsh'';
}

