D=src/content/docs
A=../.aid/works/work-005-site-rework/site-audit.md
code() { awk '/^ *(```|~~~)/{c=!c;next} !c' "$1" | sed 's/`[^`]*`//g'; }
row() { local n; n=$(grep -cF "| \`$D/$1\` " "$A"); [ "$n" = 1 ] || echo "rows=$n: $1"
  grep -F "| \`$D/$1\` " "$A" | awk -F'|' -v p="$1" -v ok="${2:-ok|corrected}" '{v=$4; c=$5; gsub(/^ +| +$/,"",v);
  gsub(/^ +| +$/,"",c); if (v !~ ("^(" ok ")$") || (v != "ok" && c == "")) print "row " p ": " v}'; }
p1() { node -e 'const s=require("fs").readFileSync(process.argv[1],"utf8"); const m=s.match(/^---\n([\s\S]*?)\n---\n/); const d=((m[1].match(/^description:\s*(.*)$/m)||[])[1]||"").trim().replace(/^(["\x27])(.*)\1$/,"$2"); const raw=(s.slice(m[0].length).split(/\n\s*\n/).map(x=>x.trim().replace(/\s*\n\s*/g," ")).filter(x=>x&&!/^import\s/.test(x))[0])||""; const plain=x=>x.replace(/\[([^\]]*)\]\([^)]*\)/g,"$1").replace(/<a\s[^>]*>([\s\S]*?)<\/a>/g,"$1").replace(/\*\*|__|`/g,""); const p=plain(raw); const n=(p.match(/[.!?](\s|$)/g)||[]).length; if(p!==plain(d)||n!==1) console.log(process.argv[1]+": P1 fails");' "$1"; }
p4() { code "$1" | grep -nE '\b[0-9]+ (skills?|shortcuts?|doorways?|agents?|catalog rows|rows|documents)\b' | sed "s#^#$1 P4: #"; }
p5() { code "$1" | grep -niE 'no longer|formerly|was retired|\b(feature|task|delivery|work)-[0-9]{3}\b|\b(N?FR|AC|KI)-[0-9]+\b' | sed "s#^#$1 P5: #"; }
p7() { code "$1" | grep -niE '\[(here|click here)\]|(^|[^("=])https?://' | sed "s#^#$1 P7: #"; }
p8() { awk 'FNR==1{p=0;c=0} /^ *(```|~~~)/{c=!c;next} !c&&/^#+ /{l=index($0," ")-1; if(l<2||(p&&l>p+1)||(!p&&l!=2))print FILENAME" P8: "$0; p=l}' "$1"
  grep -HiE '^#+ (table of )?contents$' "$1"; }
olds() { code "$1" | grep -nE '(\]\(|href=")(/get-started|/concepts|/concepts/overview|/reference|/reference/skills)/?(#[^)"]*)?("|\))' | sed "s#^#$1 old URL: #"; }
cmds() { grep -ohE '(^|[[:space:]`(">[])/aid-[a-z][a-z-]*([^A-Za-z0-9_./-]|$)' "$@" | sed -E 's#^.*/(aid-[a-z-]*[a-z]).*$#\1#' | sort -u |
  while read -r s; do test -d "../canonical/skills/$s" || grep -qE "^  - name: $s\$" ../canonical/aid/templates/shortcut-catalog.yml || echo "unknown command: /$s"; done; }
leads() { sed -n '/^## Leads found at Specify/,$p' "$A" | grep '^| /' | cut -d'|' -f2 | tr ',' '\n' | sed 's/^ *//;s/ *$//' | grep -xF "$1"; }
links() { node --input-type=module -e "import { findBrokenLinks } from './tests/dist.mjs'; for (const l of findBrokenLinks()) console.log(l);"; }
