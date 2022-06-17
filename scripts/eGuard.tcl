#_______________________________________________________.
# _ |
# | | |
# ___ __ _ __ _ __| |_ __ ___ _ __ ___ ___ |
# / _ \/ _` |/ _` |/ _` | '__/ _ \| '_ \ / _ \/ __| |
# | __/ (_| | (_| | (_| | | | (_) | |_) | __/\__ \ |
# \___|\__, |\__, |\__,_|_| \___/| .__(_)___||___/ |
# __/ | __/ | | | |
# |___/ |___/ |_| |
# |
# Autor, |
# Sentencia, #eggdrop @ irc.chathispano.com |
# Agosto de 2014 |
# ______________________________________________________|
# Este script está hecho enteramente (lo que es humanamente editable) en Español
# para eggdrop.es y el buen uso que le puedas dar en tu canal de tu red.
# Recuerda que la única descarga válida es desde http://eggdrop.es, así evitarás
# que una copia de este script con el código modificado pueda vulnerar la
# estabilidad de tu eggdrop.
#
# Este script se distribuye "así como es", sin garantía de ningún tipo. Utiliza
# este software bajo tu riesgo.
#

namespace eval eGuard {

variable settings
variable Events
array set Events {
JOIN {reban akick maxclone flood-join}
PART {spam}
NEWNICK {reban flood-nick}
PRIVMSG {cap colors cervantes spam helper repeat flood-msg}
CTCP {flood-ctcp}
}
# Setting --
# Una manera fresca de guardar la scripturación del script sin tener
# que escribir un fichero con los datos.
# Se crea un setudef str llamado script_script y ahí se guarda la
# scripturación global, y después se va modificando
# La límitación está en la longitud del contenido que sólo es 493 caracteres
# $subCmd puede ser: script settings
# $target puede ser: nombre de canal o default
# $key puede ser: nombre de settingsuración
proc Setting {subCmd target chan {arguments ""}} {
variable settings

if {$chan eq {*}} {
set chan {default}
}
if {$target eq "config"} {
set protection [lindex [split $arguments " "] 0]
set option [lindex [split $arguments " "] 1]
if {$protection ni [dict keys [dict get $eGuard::settings config default]]} {
return 0
}
if {![dict exists $settings $target $chan $protection]} {
foreach {defaultKey defaultVal} [dict get $settings $target default $protection] {
dict set settings $target $chan $protection $defaultKey $defaultVal
}
}
}
switch -- $subCmd {
get {
if {![dict exists $settings $target $chan {*}$arguments]} {
return
}

return [dict get $settings $target $chan {*}$arguments]
}
set - unset {
catch {dict $subCmd settings $target $chan {*}$arguments; Save}
}
unset {

}
incr {
if {![dict exists $settings $target $chan {*}[lrange $arguments 0 end-1]]} {
set incr 0
} else {
set incr [dict get $settings $target $chan {*}[lrange $arguments 0 end-1]]
}
set new [lindex $arguments end]
set total [incr incr $new]
dict set settings $target $chan {*}[lrange $arguments 0 end-1] $total
return $total
}
valid {
return [dict exists $settings $target $chan {*}$arguments]
}
}
}
proc Msg {target text} {
putserv "PRIVMSG $target :$text"
}
proc StripCodes {text} {
return [regsub -all -- {\017|\002|\037|\026|\003(\d{1,2})?(,\d{1,2})?} $text ""]
}
proc Config {chan key} {
return [Setting get config $chan $key]
}
proc Script {key} {
return [Setting get script default $key]
}
proc History {chan protection nick} {
return [Setting get history $chan "$protection $nick"]
}
proc Purge {chan protection nick} {
Setting unset history $chan "$protection $nick"
}

if {![info exists settings]} {
set state {recargado}
} else {
set state {iniciado}
}
proc Save {} {
variable settings
set file [Script dataFile]
if {![file isdirectory [file dirname $file]]} {
if {[catch {file mkdir [file dirname $file]} errMsg]} {
putlog "eGuard error creando [file dirname $file]: $errMsg"
return
}
}
if {[catch {set fs [open $file "w"]} errMsg]} {
putlog "eGuard: error guardando fichero de configuración- $errMsg"
return
}
puts $fs $settings
close $fs
}
proc Load {} {
variable settings
set file [Script dataFile]
if {[catch {set fs [open $file "r"]} errMsg]} {
return false
}
set storedData [read $fs]
close $fs
set origVersion [dict get $storedData script default version]
set currentVersion [dict get $settings script default version]
if {$currentVersion > $origVersion} {
putlog "Se ha detectado una versión del fichero de configuración anticuada. Actualizando datos..."
file copy -force $file $file.backup
set settings [Merge $storedData $settings]
} else {
set settings $storedData
}


}
# merge --
# Mezcla la configuración actual con la nueva.
# La configuración actual es origData y es el contenido del fichero
# eguard.dict dentro del directorio de configuración.
# newData contiene la configuración por defecto de la versión que ahora
# mismo se está se está arrancando.
proc Merge {a b} {
dict for { k v } $b {
# key exists in a and b? let's see if both values are dicts
if {[dict exists $a $k]} {
# both are dicts, so merge the dicts
if {([isDict [dict get $a $k]]) && ([isDict $v])} {
dict set a $k [Merge [dict get $a $k] $v]
} else {
dict set a $k $v
}
} else {
dict set a $k $v
}
}
return $a
}
proc isDict {d} {
return [expr {[llength $d] % 2 == 0 ? 1 : 0}]
}
# Protecciones


proc Doflood-join {chan nick setup string} {
array set settings $setup
set total [Setting incr flood-join $chan "$nick 1"]
if {$total >= $settings(events)} {
return $total
}
if {[utimerexists [list [namespace current]::Setting unset flood-join $chan $nick]] eq ""} {
utimer $settings(seconds) [list [namespace current]::Setting unset flood-join $chan $nick]
}
return "false"
}

proc Doflood-msg {chan nick setup string} {
array set settings $setup
set total [Setting incr flood-msg $chan "$nick 1"]
if {$total >= $settings(events)} {
return $total
}
if {[utimerexists [list [namespace current]::Setting unset flood-msg $chan $nick]] eq ""} {
utimer $settings(seconds) [list [namespace current]::Setting unset flood-msg $chan $nick]
}
return "false"
}
proc Doflood-nick {chan nick setup string} {
array set settings $setup
set total [Setting incr flood-nick $chan "$nick 1"]
if {$total >= $settings(events)} {
return $total
}
if {[utimerexists [list [namespace current]::Setting unset flood-nick $chan $nick]] eq ""} {
utimer $settings(seconds) [list [namespace current]::Setting unset flood-nick $chan $nick]
}
return "false"
}
proc Doflood-ctcp {chan nick setup string} {
array set settings $setup
set total [Setting incr flood-ctcp $chan "$nick 1"]
if {$total >= $settings(events)} {
return $total
}
if {[utimerexists [list [namespace current]::Setting unset flood-ctcp $chan $nick]] eq ""} {
utimer $settings(seconds) [list [namespace current]::Setting unset flood-ctcp $chan $nick]
}
return "false"
}

proc Domaxclone {chan nick setup args} {
array set settings $setup
lassign [split $nick {!@}] nick ident host
set clone 0
foreach user [chanlist $chan] {
set chanhost [lindex [split [getchanhost $user $chan] {@}] 1]
if {[string match -nocase $host $chanhost]} {
incr clone
}
if {$clone >= $settings(max)} {
return $host
}
}
return "false"
}
proc Dorepeat {chan nick setup string} {
array set settings $setup
regsub -all {\"|\{|\}\|[]\|\]|\s|[[:digit:]]} $string "" string
set string [string tolower $string]
set total [Setting incr repeat $chan "$string$nick 1"]
if {$total >= $settings(repeats)} {
return $total
}
if {[utimerexists [list [namespace current]::Setting unset repeat $chan "$string$nick"]] eq ""} {
utimer $settings(seconds) [list [namespace current]::Setting unset repeat $chan "$string$nick"]
}
return "false"
}
proc Docap {chan nick setup string} {
array set settings $setup

set string [StripCodes $string]
regsub -all {(D)\1+} $string {\1} string
if {[string length $string] <= $settings(minLength)} {
return "false"
}
set upcase 0
set lowcase 0
foreach word [split $string " "] {
if {![onchan $word $chan]} {
append parsedString "$word "
} else {
append parsedString "[string tolower $word] "
}
}
set upcase [regexp -all {[[:upper:]]} $parsedString]
if {$upcase == 0} {
return "false"
}
set lowcase [regexp -all {[[:lower:]]} $parsedString]
if {[expr {$upcase + $lowcase}] <= $settings(minLength)} {
return "false"
}
set stringLength [expr {$upcase + $lowcase}]
set percent [format %.2f [expr {($upcase / $stringLength) * 100.0}]]
if {$percent >= $settings(percent)} {
return $percent
}
return "false"
}

proc Doreban {chan uhost setup args} {
array set settings $setup
set nick [lindex [split $uhost {!}] 0]
set banmask [Setting get reban $chan $nick]
if {$banmask ne ""} {
if {[ischanban $banmask $chan]} {
return $nick
} else {
Setting unset reban $chan $banmask
}
} else {
set inAlias [inAlias $nick]
if {$inAlias ne ""} {
set banmask [Setting get reban $chan $inAlias]
if {$banmask ne ""} {
if {[ischanban $banmask $chan]} {
return "$nick o más bien $inAlias"
} else {
Setting unset reban $chan $banmask
}
}
}
if {[string length $nick] < $settings(minLength)} {
return "false"
}
set banList [Setting get reban $chan]
foreach {bannedNick bannedMask} $banList {
if {![ischanban $bannedMask $chan]} {
Setting unset reban $chan $bannedMask
continue
}
set similar [Similar $bannedNick $nick]
if {$similar <= $settings(predictive)} {
return "$nick o quizás $bannedNick"
}
}

}
return "false"
}

proc Docervantes {chan uhost setup string} {
array set settings $setup
set nick [lindex [split $uhost {!}] 0]
if {[string length $string] >= $settings(length)} {
set chanjoin [getchanjoin $nick $chan]
set now [clock seconds]
set onjoin [expr {$now - $chanjoin}]
if {$onjoin <= $settings(onjoin)} {
return true
}
}
return "false"
}
proc Docolors {chan uhost setup string} {
array set settings $setup
set nickOnChan 0
set checkNick [StripCodes [lindex [split $string " "] 0]]
foreach nickInList [chanlist $chan] {
set nickInListpattern [string trim $nickInList "\{\}\[\]:.;,^"]
set nickInListpattern [t2p $nickInList]
if {[regexp -nocase $nickInListpattern [string trim $checkNick "\{\}\[\]:.;,^"]]} {
set nickCodes [regexp -all -- {\002|\037|\026|\003([02-9]|,\d|1\d|1,\d)} [lindex [split $string " "] 0]]
if {$nickCodes >= $settings(maxNickColors)} {
return "Nick Completion"
} else {
set string [join [lrange [split $string " "] 1 end] " "]
}
break
}
}
if {$settings(strict) == 1} {
regsub -all -- {\003(\d{1,2})http} $string "http" string
regsub -all -- {\003(\d{1,2})www\.} $string "www." string
regsub -all -- {\003(\d{1,2})xD\.} $string "xD" string
}
set codes [string map [list "\002" {negritas} "\037" {subrayado} "\003" {colores}] $string]
set textCodes [regexp -all -inline -- {\002|\037|\026|\003([02-9]|,\d|1\d|1,\d)} $string]
set textTotalCodes [llength $textCodes]
if {$textTotalCodes >= $settings(maxTextColors)} {
regsub -all {[[:digit:]]} $textCodes "" textCodes
set text [string map [list "\002" {negritas} "\037" {subrayado} "\003" {colores}] $textCodes]
set text [lsort -unique $text]
set text [lsearch -all -inline -not $text {}]
return [join $text {, }]
}
return "false"
}

proc Dohelper {chan uhost setup string} {
array set settings $setup
foreach {mask reason} [Config $chan "helper list"] {
if {[regexp -nocase $mask $string]} {
set noRepeat [Setting get helper $chan $mask]
if {$noRepeat eq ""} {
Setting set helper $chan "$mask [clock seconds]"
} else {
set timeNoRepeat [expr {[clock seconds] - $noRepeat}]
if {$timeNoRepeat >= $settings(noRepeat)} {
Setting unset helper $chan $mask
} else {
return "false"
}
}
return $reason
}
}
return "false"
}
proc Doakick {chan uhost setup args} {
array set settings $setup
foreach {banmask reason} [Config $chan "akick except"] {
if {[string match -nocase $banmask $uhost]} {
return "false"
}
}
foreach {banmask reason} [Config $chan "akick list"] {
if {[string match -nocase $banmask $uhost]} {
return $reason
}
}
return "false"
}
proc Dospam {chan nick setup string} {
array set settings $setup
foreach exceptSpam [Config $chan "spam except"] {
if {[regexp -nocase -- $exceptSpam $string]} {
return "false"
}
}
foreach {banmask reason} [Config $chan "spam list"] {
if {[regexp -nocase $banmask $string]} {
return $reason
}
}
return "false"
}

proc Banrotate {args} {
foreach chanName [channels] {
if {[channel get $chanName eguard-banrotate]} {
set banTime [Config $chanName "banrotate banTime"]
set banTime [expr {$banTime * 60}]
foreach line [chanbans $chanName] {
lassign [split $line " "] banmask operator timeago
if {![string is digit -strict $timeago]} {
set timeago 0
}
if {$timeago >= $banTime} {
set report [Config $chanName "banrotate report"]
set action [string map [list {%banmask} $banmask {%details} [duration $timeago]] $report]
putserv $action
pushmode $chanName -b $banmask

}
}
}
}
}

# Eventos
proc EventBan {nick uhost hand chan mode target} {
if {![channel get $chan eguard-reban]} {
return
}
set bannedList
if {$mode eq {+b}} {
foreach user [chanlist $chan] {
set chanhost [getchanhost $user $chan]
if {[string match -nocase $target $user!$chanhost]} {
Setting set reban $chan "$user $target"
putlog "eGuard::Reban- ban \[(${chan}/${user}) $target\]"
}
}
} elseif {$mode eq {-b}} {
foreach {bannedNick banmaskBanned} [Setting get reban $chan] {
if {$banmaskBanned eq $target} {
putlog "eGuard::Reban- purgado $bannedNick (unban $target)"
Setting unset reban $chan $bannedNick
}
}
}
}

proc EventPub {nick uhost hand chan text} {
Control {PRIVMSG} $nick!$uhost $hand $chan $text
}
proc EventNotc {nick uhost hand chan text} {
if {![validchan $chan]} {
return
}
Control {PRIVMSG} $nick!$uhost $hand $chan $text
}
proc EventCTCP {nick uhost hand chan key text} {
if {![validchan $chan]} {
return
}
Control {PRIVMSG} $nick!$uhost $hand $chan $text
}
proc EventJoin {nick uhost hand chan} {
Control {JOIN} $nick!$uhost $hand $chan
}
proc EventPart {nick uhost hand chan text} {
Control {PART} $nick!$uhost $hand $chan $text
}
proc EventNick {nick uhost hand chan newNick} {
Control {NEWNICK} $newNick!$uhost $hand $chan
}
proc EventDcc {hand idx text} {
Admin putdcc $idx "" $hand $text
}
proc EventAdminMsg {nick uhost hand text} {
Admin Msg $nick $uhost $hand $text
}
proc Admin {send idx uhost hand text} {
set command [lindex [split $text " "] 0]
set udeflags [Script udeflags]
set commands
set protection [lsearch -inline -nocase $udeflags $command]
set defaultChan [lindex [split [getuser $hand console] ] 0]
if {$send eq "putdcc"} {
array set color {
black "\033\[30m"
red "\033\[31m"
green "\033\[32m"
yellow "\033\[33m"
blue "\033\[34m"
magenta "\033\[35m"
cyan "\033\[36m"
white "\033\[37m"
creset "\033\[39m"
bold "\033\[1m"
breset "\033\[0m"
}
} else {
array set color {
black "\0031"
red "\0034"
green "\0033"
yellow "\0038"
blue "\00312"
magenta "\0036"
cyan "\00311"
white "\0030"
creset "\003"
bold "\002"
breset "\002"
}
}
array set verify {
safeMode boolean
memory digit
report wordchar
ignoreop boolean
ignorevoice boolean
ignorefriend boolean
action list
minLength digit
percent digit
banTime digit
strict boolean
maxTextColors digit
maxNickColors digit
noRepeat digit
}
# USO: .eguard <protección> [canal] <opción> <parámetro>=<valor>
# .eguard spam #eggdrop add (*http*) =kickban %chan %nick a mamarla
# .eguard spam #eggdrop set safemode =1

if {$text eq ""} {
$send $idx "Comandos disponibles: \'[join $commands {, }], [join $udeflags {, }], <+|->protección\' - usa .eguard <comando>"
return
}

switch -nocase -glob $command {
{about} {
$send $idx "[Script name] [Script version] \[(c) [Script hosting] - [Script author]\]"
return
}
{stats} {
# .eguard stats #eggdrop reban 2014-12-01
set chan [lindex [split $text " "] 1]
if {![validchan $chan]} {
set chan $defaultChan
if {![validchan $chan]} {
$send $idx "Canales disponibles: [join [channels] {, }] -- usa .eguard stats \[#canal\] \[${protection}\] \[YYYY-mm-dd\]"
return
}
set text [join [lrange [split $text " "] 1 end] " "]
} else {
set text [join [lrange [split $text " "] 2 end] " "]
set udeflag [lindex [split $text " "] 2]
set date [lindex [split $text " "] 3]
}
set udeflag [lindex [split $text " "] 0]
if {$udeflag ne ""} {
if {$udeflag ni $udeflags} {
foreach defaultUdeflag $udeflags {
if {[Similar $defaultUdeflag $udeflag] < 3} {
$send $idx "¿Quizás quisiste decir... ${defaultUdeflag}?"
set udeflag $defaultUdeflag
break
}
}
if {$udeflag ni $udeflags} {
$send $idx "protección no válida. Usa una de estas: [join $udeflags {, }]"
return
}
}
set text [join [lrange [split $text " "] 1 end] " "]
} else {
set udeflag $udeflags
}
set date [lindex [split $text " "] 0]
if {$date eq ""} {
set date [clock format [clock seconds] -format "%Y-%m-%d"]
}
foreach u $udeflag {
$send $idx "\[(stats/${chan}) $date\]: $u - usos: [Stats $chan $date $u]"
}
return
}
{alias} {
set subAliasCmd [lindex [split $text " "] 1]
set aliasArguments [join [lrange [split $text " "] 2 end] " "]
set parameter [lindex [split $aliasArguments {=}] 0]
set value [join [lrange [split $aliasArguments {=}] 1 end] {=}]
switch -nocase $subAliasCmd {
{add} {
if {$parameter eq ""} {
$send $idx "Indica el nick principal del usuario y después su alias -- .eguard alias add nick=segundoNick"
return
}
if {$value eq ""} {
$send $idx "Indica un segundo nick como alias de $parameter"
return
}
set aliasList [Config default [list alias list $parameter]]
if {$aliasList eq ""} {
Setting set config default [list alias list $parameter $value]
} else {
lappend aliasList $value
set aliasList [lsort -unique $aliasList]
Setting set config default [list alias list $parameter "$aliasList"]
}
set result [Setting get config default [list alias list $parameter]]
}
{del} - {delete} {
set exists [Config default [list alias list $parameter]]
if {$exists eq ""} {
$send $idx "$parameter no tiene ningún alias."
return
}
Setting unset config default [list alias list $parameter]
set result {alias eliminado.}
}
{list} {
if {$parameter ne ""} {
set list [Config default [list alias list $parameter]]
} else {
set list [Config default
]
}

if {$list eq ""} {
$send $idx {No hay entradas.}
return
}
set i 0
foreach {key val} $list {
$send $idx "alias [incr i]: $key = $val"
}
return
}
default {
$send $idx "Comandos disponibles add, list, del"
return
}
}
$send $idx "${color(green)}OK: \[(alias/${color(bold)}${parameter}${color(breset)})\]: $result $color(creset)"
return
}
{chan} {
set newChan [lindex [split $text " "] 1]
set adminChanlist [AdminChanlist $hand]
if {$newChan ni $adminChanlist} {
$send $idx "Indica qué canal quieres configurar por defecto: [join $adminChanlist {, }]."
return
} else {
setuser $hand console $newChan
$send $idx "Canal por defecto: [lindex [split [getuser $hand console] ] 0]"
return
}
}
{+*} - {-*} {
set chan [lindex [split $text " "] 1]
if {(![validchan $chan]) && ($chan ne {*})} {
set chan $defaultChan
if {![validchan $chan]} {
$send $idx "Canales disponibles: [join [channels] {, }] -- usa .eguard <${protection}> \[#canal\]"
return
}
}
set udeflag [string range $command 1 end]
set flagMode [string index $command 0]
if {$udeflag ni $udeflags} {
foreach defaultUdeflag $udeflags {
if {[Similar $defaultUdeflag $udeflag] < 3} {
$send $idx "¿Quizás quisiste decir... ${defaultUdeflag}?"
set udeflag $defaultUdeflag
break
}
}
if {$udeflag ni $udeflags} {
$send $idx "protección desconocida. Usa una de estas: [join $udeflags {, }]."
return
}
}
channel set $chan ${flagMode}eguard-${udeflag}
$send $idx "OK $udeflag [expr {$flagMode == {+} ? "activado" : "desactivado"}] en $chan."
return
}
{logo} {
set newLogo [lindex [split $text " "] 1]
Setting set script default "logo $newLogo"
$send $idx "OK: nuevo logo: $newLogo"
return
}
{info} {
set chan [lindex [split $text " "] 1]
if {![validchan $chan]} {
set chan $defaultChan
if {![validchan $chan]} {
$send $idx "Canales disponibles: [join [channels] {, }] -- usa .eguard info <${protection}> \[#canal\]"
return
}
set protection [lindex [split $text " "] 1]
} else {
set protection [lindex [split $text " "] 2]
}
set protection [lsearch -inline -nocase $udeflags $protection]
if {$protection eq ""} {
$send $idx "eGuard info de $chan"
$send $idx "[format "| %10s : %-11s : %-14s" {Protección} {Estado} {Modo seguro}]"
foreach udeflag $udeflags {
set chanState [channel get $chan eguard-${udeflag}]
unset -nocomplain state
array set chanSetup [Config $chan $udeflag]
if {[bool $chanState]} {
append state "activado"
} else {
append state "desactivado"
}
if {[bool $chanSetup(safeMode)]} {
set safeMode {(en pruebas)}
} else {
set safeMode {(en producción)}
}
$send $idx "[format "| %10s : %-11s : %-14s" ${udeflag} $state $safeMode]"
}
} else {
array set translation [Script translation]
array set chanSetup [Config $chan $protection]
$send $idx "---\neGuard info de $protection en ${chan}:"
$send $idx "[format "| %15s : %11s : %-48s" {set} {Detalle} {Valor actual}]"
$send $idx "[format "|${color(bold)} %15s ${color(breset)}: %11s : %-48s" {safeMode} {Modo seguro} [expr {[bool $chanSetup(safeMode)] == 1 ? "Sí" : "no"}]]"
$send $idx "[format "|${color(bold)} %15s ${color(breset)}: %11s : %-48s" {memory} {Memoria} "$chanSetup(memory) minutos"]"
$send $idx "[format "|${color(bold)} %15s ${color(breset)}: %11s : %-48s" {report} {Reporte} "$chanSetup(report)"]"
# $send $idx "+----------------------------------------------------------------------------------+"
$send $idx "[format "|${color(bold)} %15s ${color(breset)}: %11s : %-48s" {ignoreop} {@ inmunes} [expr {[bool $chanSetup(ignoreop)] == 1 ? "Sí" : "no"}]]"
$send $idx "[format "|${color(bold)} %15s ${color(breset)}: %11s : %-48s" {ignorevoice} {+v inmunes} [expr {[bool $chanSetup(ignoreop)] == 1 ? "Sí" : "no"}]]"
$send $idx "[format "|${color(bold)} %15s ${color(breset)}: %11s : %-48s" {ignorefriend} {+f inmunes} [expr {[bool $chanSetup(ignoreop)] == 1 ? "Sí" : "no"}]]"
# $send $idx "+==================================================================================+"
$send $idx "[format "| %15s : %11s : %-48s" {set} {Acciones} {castigos correspondientes a cada ofensa}]"
# $send $idx "+==================================================================================+"
foreach {key val} [Config $chan "$protection action"] {
$send $idx "[format "|${color(bold)} %15s ${color(breset)}: %11s : %-48s" "action $key" "Castigo $key" $val]"
}
# $send $idx "+==================================================================================+"
$send $idx "[format "| %15s : %11s : %-48s" {set} {Detalle} "opciones específicas para esta protección. Usa .help eguard opción para más información"]"

# $send $idx "+==================================================================================+"
#report ignorefriend safeMode percent memory action minLength ignorevoice ignoreop
set skipOptions [list {list} {ignorefriend} {ignoreop} {ignorevoice} {safeMode} {memory} {action} {report}]
foreach {key val} [array get chanSetup] {
if {$key ni $skipOptions} {
if {[info exists translation($key)]} {
set translate $translation($key)
} else {
set translate $key
}
$send $idx "[format "|${color(bold)} %15s ${color(breset)}: %11s : %-48s" $key $translate "$val"]"
}
if {$key eq {list}} {
$send $idx "[format "| %30s %-48s" {Listado} {}]"
$send $idx "[format "| %29s : %-48s" {patrón} {detalles}]"
foreach {listKey listVal} $val {
$send $idx "[format "|${color(bold)} %28s ${color(breset)} : %-48s" $listKey $listVal]"
}
}
}
# $send $idx "+----------------------------------------------------------------------------------+"
}
return
}
default {}

}
if {$protection ne ""} {
set chan [lindex [split $text " "] 1]
if {![validchan $chan]} {
set chan $defaultChan
if {![validchan $chan]} {
$send $idx "Canales disponibles: [join [channels] {, }] -- usa .eguard <${protection}> \[#canal\]"
return
}
set option [lindex [split $text " "] 1]
set arguments [join [lrange [split $text " "] 2 end] " "]
} else {
set option [lindex [split $text " "] 2]
set arguments [join [lrange [split $text " "] 3 end] " "]
}
if {[regexp {^(\+|\-)} $protection "" flagMode]} {
set enableFlag [string trim [string range $protection 1 end]]
set enableFlag [lsearch -inline -nocase $udeflags $enableFlag]
if {$enableFlag eq ""} {
$send $idx "No es una protección válida. Las protecciones válidas son: [join $udeflags {, }]."
return
} else {
channel set $chan ${flagMode}eguard-${enableFlag}
$send $idx "OK. ${enableFlag} [expr {$flagMode == {+} ? "activado" : "desactivado"}] en ${chan}"
return
}
}
set parameter [lindex [split $arguments {=}] 0]
set value [join [lrange [split $arguments {=}] 1 end] {=}]
array set options {
helper {exceptadd exceptlist exceptdel add list del set}
akick {aliasadd aliaslist aliasdel exceptadd exceptlist exceptdel add list del set}
spam {exceptadd exceptlist exceptdel add list del set}
alias {add list del}
flood-msg {set}
flood-ctcp {set}
flood-join {set}
flood-nick {set}
cervantes {set}
maxclone {set}
cap {set}
reban {set}
colors {set}
banrotate {set}
troll {set}
repeat {set}
}
set option [lsearch -inline -nocase $options($protection) $option]
if {$option eq ""} {
$send $idx "Opciones disponibles: [join $options($protection) {|}]. -- usa .eguard $protection \[#canal\] <opción>"
return
}
set parameters [dict keys [Setting get config default $protection]]
if {($option eq {set}) && ($parameter eq "")} {
$send $idx "Parámetros disponibles: [join $parameters {, }]. -- usa .eguard $protection \[#canal\] <opción> <parámetro>=<valor>"
return
}
switch -nocase -glob $option {

{exceptadd} {
if {$parameter eq ""} {
$send $idx "Indica el nuevo parámetro para añadir como excepción."
return
}
Setting set config $chan [list $protection except $parameter "1"]
set result {añadido como excepción.}
}
{exceptdel} {
array set protectionList [Config $chan [list $protection except]]
if {[array names protectionList] eq ""} {
$send $idx "La lista de $protection está vacía."
return
}
if {![string is digit -strict $parameter]} {
$send $idx "Indica el número ID que aparece en .eguard $protection list para eliminar el parámetro."
return
}
incr $parameter -1
set index [lindex [array names protectionList] $parameter]
array unset protectionList $index
Setting set config $chan [list $protection except [array get protectionList]]
set result "$index eliminado."
}
{exceptlist} {
set list [Config $chan "$protection except"]
if {$list eq ""} {
$send $idx {No hay entradas.}
return
}
set i 0
foreach {key val} $list {
$send $idx "$protection list [incr i]: $key"
}
return
}
{add} {
if {$value eq ""} {
$send $idx "Añade el nuevo valor para el parámetro $parameter"
return
}
Setting set config $chan [list $protection list $parameter $value]
set result [Setting get config $chan [list $protection list $parameter]]
}
{del} {
set protectionList [lsort [dict keys [Config $chan "$protection list"]]]
if {$protectionList eq ""} {
$send $idx "La lista de $protection está vacía."
return
}
if {![string is digit -strict $parameter]} {
$send $idx "Indica el número ID que aparece en .eguard $protection list para eliminar el parámetro."
return
}
set i -1
foreach key $protectionList {
putlog "[incr i] ($parameter)> $key = [Config $chan [list $protection list $key]]"
}
set index [lindex $protectionList [expr {$parameter -1}]]
Setting unset config $chan [list $protection list $index]
set result "$index eliminado."
}
{list} {
set list [lsort [dict keys [Config $chan "$protection list"]]]
if {$list eq ""} {
$send $idx "No hay entradas."
return
}
set i 0
foreach key $list {
$send $idx "$protection list [incr i]: $key = [Config $chan [list $protection list $key]]"
}
return
}
{set} {
if {$parameter ne ""} {
if {[string match -nocase {action*} $parameter]} {
set actionNumber [lindex [split $parameter " "] 1]
if {![string is digit -strict $actionNumber]} {
$send $idx "Indica la posición de esta acción -- usa .eguard $protection \[#canal\] <opción> action <número>=<valor>"
return
}
set parameter "action $actionNumber"
} else {
set parameter [lsearch -inline -nocase $parameters $parameter]
}
}
if {$parameter eq ""} {
$send $idx "Parámetros disponibles: [join $parameters {, }]. -- usa .eguard $protection \[#canal\] <opción> <parámetro>=<valor>"
return
}
if {$value eq ""} {
$send $idx "Añade el nuevo valor para el parámetro $parameter"
return
}
Setting set config $chan [list $protection {*}$parameter $value]
Save
set result [Setting get config $chan [list $protection {*}$parameter]]
}
default {
$send $idx "Opciones disponibles: [join $options($protection) {|}]. -- usa .eguard $protection \[#canal\] <opción>"
return
}
}
$send $idx "${color(green)}OK: \[(${chan}/${color(bold)}${protection}${color(breset)})\]: $parameter = $result $color(creset)"
return
} else {
$send $idx "Comandos disponibles: \'[join $commands {, }], [join $udeflags {, }], <+|->protección\' - usa .eguard <comando>"
return
}

}
#
proc Control {eventName user hand args} {
variable Events
lassign [split $user {!@}] nick ident host
switch $eventName {
{PRIVMSG} {
set chan [lindex $args 0]
set text [join [lrange $args 1 end]]
}
{JOIN} - {NEWNICK} - {PART} {
set chan [lindex $args 0]
set text {}
}
}
if {[isbotnick $nick]} {
return
}
if {![validchan $chan]} {
return
}
set options $Events($eventName)
set troll [Config $chan "troll offenses"]
set offenses($nick)
foreach protection $options {
set udeflag eguard-${protection}
if {![channel get $chan $udeflag]} {
continue
}
array set setup [Config $chan $protection]

if {[bool $setup(ignoreop)]} {
if {([isop $nick $chan]) || ([matchattr $hand o $chan])} {
continue
}
}
if {[bool $setup(ignorevoice)]} {
if {([isvoice $nick $chan]) || ([matchattr $hand v $chan])} {
continue
}
}
if {([matchattr $hand f $chan]) && ([bool $setup(ignorefriend)])} {
continue
}
set result [Do$protection $chan $user [array get setup] $text]
array set translation [Script translation]
if {$result ne "false"} {
lappend offenses($nick) [list $protection $result]
lappend trollDetails $translation($protection)
}
}

if {[llength [lsearch -all -not $offenses($nick) {helper*}]] >= $troll} {
Offense troll $chan $nick [join $trollDetails {, }]
} else {
foreach offense $offenses($nick) {
Offense [lindex $offense 0] $chan $nick [lindex $offense 1]
}
}
return
}

#  Procs

proc Stats {chan date protection {target ""}} {
if {[string is digit $date]} {
set date [clock format $date -format "%Y-%m-%d"]
}
set stats [Setting get stats $chan [list $date $protection]]
set total 0
dict for {key val} $stats {
incr total $val
}
return $total
}
proc inAlias {target} {
set aliasList [Config default
]
foreach {key val} $aliasList {
if {[lsearch -nocase $val $target] != -1} {
return $key
}
}
return
}
proc t2p {string} {
return [regsub -all -- {(\[|\]|\\|\{|\})} $string {\\\1}]
}
proc utimerexists {command} {
foreach i [utimers] {
if {![string compare $command [lindex $i 1]]} then {
return [lindex $i 2]
}
}
return
}
proc bool {string} {
return [string is true -strict [lindex [split $string] 0]]
}
proc tempkickban {minutes chan target {message {}}} {
set banmask [kickban $chan $target $message]
timer $minutes [list pushmode $chan -b $banmask]
}
proc kickban {chan target {message {}}} {
global defaults
if {[isop $target $chan]} {
set params(-o) $target
}
if {[isvoice $target $chan]} {
set params(-v) $target
}

set banType [channel get $chan {ban-type}]
set targethost [getchanhost $target]
if {$targethost ne {}} {
set banhost [maskhost $targethost $banType]
} else {
set banhost $target!*@*
}
set params(+b) $banhost
foreach {key value} [array get params] {
lappend newmode $key
lappend newtarget $value
}
set newmode [join $newmode ""]
putquick "MODE $chan $newmode [join $newtarget " "]"

if {$message eq {}} {
set message [channel get $chan {kick-message}]
}
if {$message eq {}} {
set message $defaults(kick-message)
}
kick $chan $target $message
return $banhost
}
proc ipkickban {chan target {message {}}} {
global defaults
if {[isop $target $chan]} {
set params(-o) $target
}
if {[isvoice $target $chan]} {
set params(-v) $target
}

set banType [channel get $chan {ban-type}]
set targethost [getchanhost $target]
if {$targethost ne {}} {
set banhost [maskhost $targethost $banType]
} else {
set banhost $target!*@*
}
set params(+b) $banhost
foreach {key value} [array get params] {
lappend newmode $key
lappend newtarget $value
}
set newmode [join $newmode ""]
putquick "MODE $chan $newmode [join $newtarget " "]"

if {$message eq {}} {
set message [channel get $chan {kick-message}]
}
if {$message eq {}} {
set message $defaults(kick-message)
}
kick $chan $target $message
return $banhost
}
proc unban {chan target} {
global defaults

if {![regexp (\\*|\\?) $target]} {

if {[isop $target $chan]} {
set params(-o) $target
}
if {[isvoice $target $chan]} {
set params(-v) $target
}
set banType [channel get $chan {ban-type}]
set targethost [getchanhost $target]
if {$targethost ne {}} {
set banhost [maskhost $targethost $banType]
} else {
set banhost $target!*@*
}
} else {
set banhost $target
}
set params(-b) $banhost
foreach {key value} [array get params] {
lappend newmode $key
lappend newtarget $value
}
set newmode [join $newmode ""]
putquick "MODE $chan $newmode [join $newtarget " "]"
}

proc ban {chan target} {
global defaults

if {![regexp (\\*|\\?) $target]} {

if {[isop $target $chan]} {
set params(-o) $target
}
if {[isvoice $target $chan]} {
set params(-v) $target
}
set banType [channel get $chan {ban-type}]
set targethost [getchanhost $target]
if {$targethost ne {}} {
set banhost [maskhost $targethost $banType]
} else {
set banhost $target!*@*
}
} else {
set banhost $target
}
set params(+b) $banhost
foreach {key value} [array get params] {
lappend newmode $key
lappend newtarget $value
}
set newmode [join $newmode ""]
putquick "MODE $chan $newmode [join $newtarget " "]"
return $banhost
}
proc tempban {chan target time} {
global defaults

if {![regexp (\\*|\\?) $target]} {

if {[isop $target $chan]} {
set params(-o) $target
}
if {[isvoice $target $chan]} {
set params(-v) $target
}
set banType [channel get $chan {ban-type}]
set targethost [getchanhost $target]
if {$targethost ne {}} {
set banhost [maskhost $targethost $banType]
} else {
set banhost $target!*@*
}
} else {
set banhost $target
}
set params(+b) $banhost
foreach {key value} [array get params] {
lappend newmode $key
lappend newtarget $value
}
set newmode [join $newmode ""]
putquick "MODE $chan $newmode [join $newtarget " "]"
timer $time [list pushmode $chan -b $banhost]
}
proc kick {chan target {message {}}} {

global defaults
if {$message eq {}} {
set message [channel get $chan {kick-message}]
}
if {$message eq {}} {
set message $defaults(kick-message)
}

putquick "KICK $chan $target :[Script logo]: $message"
}
proc Similar {string text} {
# Edge cases
set s [string tolower $string]
set t [string tolower $text]
if {![set n [string length $t]]} {
return [string length $s]
} elseif {![set m [string length $s]]} {
return $n
}
# Fastest way to initialize
for {set i 0} {$i <= $m} {incr i} {
lappend d 0
lappend p $i
}
# Loop, computing the distance table (well, a moving section)
for {set j 0} {$j < $n} {} {
set tj [string index $t $j]
lset d 0 [incr j]
for {set i 0} {$i < $m} {} {
set a [expr {[lindex $d $i]+1}]
set b [expr {[lindex $p $i]+([string index $s $i] ne $tj)}]
set c [expr {[lindex $p [incr i]]+1}]
# Faster than min($a,$b,$c)
lset d $i [expr {$a<$b ? $c<$a ? $c : $a : $c<$b ? $c : $b}]
}
# Swap
set nd $p; set p $d; set d $nd
}
# The score is at the end of the last-computed row
return [lindex $p end]
}
proc AdminChanlist {hand} {
set chanlist
foreach c [channels] {
if {[matchattr $hand m|m $c]} {
lappend chanlist $c
}
}
return $chanlist
}
proc Offense {protection chan uhost {details ""}} {
lassign [split $uhost {!@}] nick user host
set total [History $chan $protection $nick]
set report [Config $chan "$protection report"]
set memory [Config $chan "$protection memory"]
set stats [Config $chan "$protection stats"]
set safeMode [Config $chan "$protection safeMode"]
if {![string is digit -strict $total]} {
set total 1
Setting set history $chan "$protection $nick $total"
} else {
set next [expr {$total + 1}]
if {[Config $chan "$protection action $next"] ne ""} {
Setting set history $chan "$protection $nick [incr total]"
}
}
if {[bool $stats]} {
Setting incr stats $chan "[clock format [clock seconds] -format "%Y-%m-%d"] $protection $nick 1"
}
set action [Config $chan "$protection action $total"]
set actionCmd [lindex [split $action " "] 0]
set action [string map [list {%chan} $chan\
{%nick} $nick\
{%details} $details\
{%offenseNumber} $total\
{%action} $actionCmd\
{%protection} $protection] $action]
if {[string match {*%stats*} $action]} {
set stats [Stats $chan [clock seconds] $protection]
set action [string map [list {%stats} $stats] $action]
}
putlog "\[(${chan}/${nick}) $total $protection\]: ${actionCmd}..."

DoOffense $safeMode $action
set report [Config $chan "$protection report"]
set report [string map [list {%chan} $chan\
{%nick} $nick\
{%details} $details\
{%offenseNumber} $total\
{%action} $actionCmd\
{%protection} $protection] $report]
if {[string match {*%stats*} $report]} {
if {![info exists stats]} {
set stats [Stats $chan [clock seconds] $protection]
}
set report [string map [list {%stats} $stats] $report]
}
DoOffense 0 $report
Setting set purge $chan "$protection [clock seconds] $nick"
if {[timerexists [list [namespace current]::Purge $chan $protection $nick]] eq ""} {
timer $memory [list [namespace current]::Purge $chan $protection $nick]
}
return
}
proc DoOffense {safeMode action} {
set action [split $action " "]
set actionCmd [lindex $action 0]
if {[bool $safeMode]} {
set actionCmd {safeMode}
}
switch -nocase $actionCmd {
{notice} - {privmsg} {
set actionTarget [lindex $action 1]
set actionArguments [join [lrange $action 2 end]]
putserv "$actionCmd $actionTarget :$actionArguments"
}
{msg} {
set actionTarget [lindex $action 1]
set actionArguments [join [lrange $action 2 end]]
putserv "privmsg $actionTarget :$actionArguments"
}
{none} - {nothing} {
return
}
{kick} - {kickban} - {ipkickban} {
set chanTarget [lindex $action 1]
set userTarget [lindex $action 2]
set actionArguments [join [lrange $action 3 end]]
$actionCmd $chanTarget $userTarget $actionArguments
}
{ban} - {unban} {
set chanTarget [lindex $action 1]
set userTarget [lindex $action 2]
$actionCmd $chanTarget $userTarget
}
{tempban} {
set chanTarget [lindex $action 1]
set userTarget [lindex $action 2]
set time [lindex $action 3]
$actionCmd $chanTarget $userTarget $time
}
{tempkickban} {
set chanTarget [lindex $action 1]
set userTarget [lindex $action 2]
set time [lindex $action 3]
set actionArguments [join [lrange $action 4 end]]
$actionCmd $time $chanTarget $userTarget $actionArguments
}
{safeMode} {
putlog "eGuard: safemode: $action"
return
}
}
}
dict set settings script default udeflags [list helper akick spam cervantes cap\
reban colors banrotate troll repeat maxclone flood-msg flood-ctcp flood-nick flood-join]
dict set settings script default translation [list list lista akick autokick spam spam length\
Longitud cervantes cervantes onjoin {Desde entrada} offenses ofensas banTime {ban tiempo}\
strict estricto maxNickColors ColoresNick maxTextColors ColoresTexto ignoreNicks ignorarNicks\
predictive predicción cap mayúsculas colors colores banrotate banrotación percent porcentaje\
minLength Longitud helper ayudante repeat repeticiones reban reban repeats repeticiones\
seconds segundos set set except excepción noRepeat {no repetir} max máximo maxclone {clones máx}\
flood-join flood-join flood-msg flood-msg flood-ctcp flood-ctcp flood-ctcp flood-ctcp\
flood-nick flood-nick]
dict set settings script default version {2.0.1}
dict set settings script default name {eGuard}
dict set settings script default logo "\002e\037G\037\002uard"
dict set settings script default author {Sentencia}
dict set settings script default hosting {http://eggdrop.es}
dict set settings script default contact {http://eggdrop.es/profile/Sentencia/}
dict set settings script default dataFile "[file join eGuard $::nick "eguard.dict"]"
# Config

dict set settings config default reban safeMode 1
dict set settings config default reban memory 15
dict set settings config default reban ignoreop 1
dict set settings config default reban ignorevoice 1
dict set settings config default reban ignorefriend 1
dict set settings config default reban report {notice @%chan %nick (%details) se saltó el ban, ejecutando %action...}
dict set settings config default reban predictive 1
dict set settings config default reban minLength 3
dict set settings config default reban stats 1
dict set settings config default reban action 1 {kickban %chan %nick %details, aún estás baneado/a. Por favor, habla con un OPerador para que eliminen tu ban.}

dict set settings config default cap safeMode 1
dict set settings config default cap memory 15
dict set settings config default cap ignoreop 1
dict set settings config default cap ignorevoice 1
dict set settings config default cap ignorefriend 1
dict set settings config default cap stats 1
dict set settings config default cap minLength 20
dict set settings config default cap percent 90
dict set settings config default cap report {notice @%chan %offenseNumber ofensa de %protection (%details%) de %nick, ejecutando %action...}
dict set settings config default cap action 1 {notice %nick Por favor las mayúsculas se usan para gritar, no las uses.}
dict set settings config default cap action 2 {msg %chan %nick: por favor escribe en minúsculas. Las mayúsculas se usan para gritar.}
dict set settings config default cap action 3 {kick %chan %nick Escribe en minúsculas.}
dict set settings config default cap action 4 {tempkickban 5 %chan %nick Expulsión durante 5 minutos. (%details% mayúsculas)}
dict set settings config default cap action 5 {kickban %chan %nick Expulsión indefinida (%details% mayúsculas)}

dict set settings config default colors safeMode 1
dict set settings config default colors memory 15
dict set settings config default colors ignoreop 1
dict set settings config default colors ignorevoice 1
dict set settings config default colors ignorefriend 1
dict set settings config default colors stats 1
dict set settings config default colors maxNickColors 10
dict set settings config default colors maxTextColors 1
dict set settings config default colors strict 0
dict set settings config default colors report {notice @%chan %offenseNumber ofensa de %protection (%details) de %nick, ejecutando %action...}
dict set settings config default colors action 1 {notice %nick %nick, estás usando un resalte de texto en %chan (%details) alguna gente no los ve y es molesto.}
dict set settings config default colors action 2 {msg %nick %nick, por favor evita enviar el texto resaltado porque no todo el mundo lo puede ver.}
dict set settings config default colors action 3 {msg %chan %nick: te envié un notice y dos privados informando del uso de %details.\
Si sigues usándolas te pueden expulsar del canal. No sigas escribiendo hasta que lo hayas corregido por favor.}
dict set settings config default colors action 4 {tempban %chan %nick 1}

dict set settings config default banrotate safeMode 1
dict set settings config default banrotate memory 15
dict set settings config default banrotate ignoreop 1
dict set settings config default banrotate ignorevoice 1
dict set settings config default banrotate ignorefriend 1
dict set settings config default banrotate stats 1
dict set settings config default banrotate banTime 720
dict set settings config default banrotate report {notice @%chan quité el ban %banmask porque ha expirado (%details)}
dict set settings config default banrotate action 1 {unban %chan %banmask}

dict set settings config default troll safeMode 1
dict set settings config default troll memory 15
dict set settings config default troll ignoreop 1
dict set settings config default troll ignorevoice 1
dict set settings config default troll ignorefriend 1
dict set settings config default troll stats 1
dict set settings config default troll offenses 2
dict set settings config default troll report {notice @%chan troll detectado %nick, (%details) en una sola línea}
dict set settings config default troll action 1 {kickban %chan %nick %details... demasiado para mí.}

dict set settings config default cervantes safeMode 1
dict set settings config default cervantes memory 15
dict set settings config default cervantes ignoreop 1
dict set settings config default cervantes ignorevoice 1
dict set settings config default cervantes ignorefriend 1
dict set settings config default cervantes stats 1
dict set settings config default cervantes length 300
dict set settings config default cervantes onjoin 80
dict set settings config default cervantes report {notice @%chan %nick escribió una frase muy larga nada más entrar}
dict set settings config default cervantes action 1 {ban %chan %nick}
dict set settings config default cervantes action 2 {kick %chan %nick Por favor, antes de escribir semejante parrafón saluda}

dict set settings config default spam safeMode 1
dict set settings config default spam memory 15
dict set settings config default spam ignoreop 1
dict set settings config default spam ignorevoice 1
dict set settings config default spam ignorefriend 1
dict set settings config default spam stats 1
dict set settings config default spam report {notice @%chan Spam de %nick (%details)}
dict set settings config default spam action 1 {tempkickban %chan %nick 15 La publicidad no está permitida en este canal.}

dict set settings config default helper safeMode 1
dict set settings config default helper memory 15
dict set settings config default helper ignoreop 0
dict set settings config default helper ignorevoice 0
dict set settings config default helper ignorefriend 0
dict set settings config default helper stats 1
dict set settings config default helper noRepeat 60
dict set settings config default helper report {none}
dict set settings config default helper action 1 {msg %chan %nick, %details}

dict set settings config default repeat safeMode 1
dict set settings config default repeat memory 15
dict set settings config default repeat ignoreop 1
dict set settings config default repeat ignorevoice 1
dict set settings config default repeat ignorefriend 1
dict set settings config default repeat stats 1
dict set settings config default repeat repeats 3
dict set settings config default repeat seconds 3
dict set settings config default repeat report {notice @%chan repeticiones de %nick, %action...}
dict set settings config default repeat action 1 {kick %chan %nick por favor no repitas.}

dict set settings config default flood-msg safeMode 1
dict set settings config default flood-msg memory 15
dict set settings config default flood-msg ignoreop 1
dict set settings config default flood-msg ignorevoice 1
dict set settings config default flood-msg ignorefriend 1
dict set settings config default flood-msg stats 1
dict set settings config default flood-msg events 5
dict set settings config default flood-msg seconds 3
dict set settings config default flood-msg report {notice @%chan flood de texto de %nick, %action...}
dict set settings config default flood-msg action 1 {kick %chan %nick por favor, escribe más despacio.}
dict set settings config default flood-msg action 2 {tempban %chan %nick 5}
dict set settings config default flood-msg action 3 {tempban %chan %nick 15}

dict set settings config default flood-join safeMode 1
dict set settings config default flood-join memory 15
dict set settings config default flood-join ignoreop 1
dict set settings config default flood-join ignorevoice 1
dict set settings config default flood-join ignorefriend 1
dict set settings config default flood-join stats 1
dict set settings config default flood-join events 5
dict set settings config default flood-join seconds 5
dict set settings config default flood-join report {notice @%chan flood de %nick, %action...}
dict set settings config default flood-join action 1 {kick %chan %nick entras y sales demasiadas veces. Elige tu lugar}
dict set settings config default flood-join action 2 {tempban %chan %nick 15}

dict set settings config default flood-nick safeMode 1
dict set settings config default flood-nick memory 15
dict set settings config default flood-nick ignoreop 1
dict set settings config default flood-nick ignorevoice 1
dict set settings config default flood-nick ignorefriend 1
dict set settings config default flood-nick stats 1
dict set settings config default flood-nick events 3
dict set settings config default flood-nick seconds 5
dict set settings config default flood-nick report {notice @%chan flood de %nick, %action...}
dict set settings config default flood-nick action 1 {kick %chan %nick actúas demasiado rápido para el ritmo del canal.}
dict set settings config default flood-nick action 2 {tempban %chan %nick 5}

dict set settings config default flood-ctcp safeMode 1
dict set settings config default flood-ctcp memory 15
dict set settings config default flood-ctcp ignoreop 1
dict set settings config default flood-ctcp ignorevoice 1
dict set settings config default flood-ctcp ignorefriend 1
dict set settings config default flood-ctcp stats 1
dict set settings config default flood-ctcp events 3
dict set settings config default flood-ctcp seconds 10
dict set settings config default flood-ctcp report {notice @%chan flood de %nick, %action...}
dict set settings config default flood-ctcp action 1 {kick %chan %nick actúas demasiado rápido para el ritmo del canal.}
dict set settings config default flood-ctcp action 2 {tempban %chan %nick 5}

dict set settings config default akick safeMode 1
dict set settings config default akick memory 15
dict set settings config default akick ignoreop 1
dict set settings config default akick ignorevoice 1
dict set settings config default akick ignorefriend 1
dict set settings config default akick stats 1
dict set settings config default akick report {notice @%chan %nick tiene akick (%details)}
dict set settings config default akick action 1 {kickban %chan %nick %details}

dict set settings config default maxclone safeMode 1
dict set settings config default maxclone memory 15
dict set settings config default maxclone ignoreop 1
dict set settings config default maxclone ignorevoice 1
dict set settings config default maxclone ignorefriend 1
dict set settings config default maxclone stats 1
dict set settings config default maxclone max 3
dict set settings config default maxclone report {notice @%chan límite de clones excedido: %details}
dict set settings config default maxclone action 1 {ipkickban %chan %nick límite de clones excedido: %details}
dict set settings config default alias {}
foreach udeflag [Script udeflags] {
setudef flag eguard-${udeflag}
}
bind pubm - * [namespace current]::EventPub
bind notc - * [namespace current]::EventNotc
bind ctcp - * [namespace current]::EventCTCP
bind join - * [namespace current]::EventJoin
bind part - * [namespace current]::EventPart
bind nick - * [namespace current]::EventNick
bind mode - "% +b" [namespace current]::EventBan
bind mode - "% -b" [namespace current]::EventBan
bind dcc m|m eguard [namespace current]::EventDcc
bind msg m|m .eguard [namespace current]::EventAdminMsg
bind time - * [namespace current]::Banrotate
Load
catch {loadhelp eguard.help}
putlog "cargado: [Script name] [Script version] \[(c) [Script hosting] - [Script author]\] ($state)"
}