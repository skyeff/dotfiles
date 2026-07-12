# ~/.config/elvish/rc.elv

fn git-branch {
  var out = ""
  var ok = $true
  try {
    set out = (git symbolic-ref --short HEAD 2>/dev/null)
  } catch {
    set ok = $false
  }
  if (and $ok (not-eq $out "")) {
    put "["$out"]"
  } else {
    put ""
  }
}

set edit:prompt = {
  styled "λ" magenta
  var gb = (git-branch)
  if (not-eq $gb "") {
    styled $gb green
  }
  styled "["(tilde-abbr $pwd)"]$ " default
}
