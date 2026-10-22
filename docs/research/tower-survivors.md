# Tower Survivors: onderzoek voor de modus Laatste toren

> Onderzocht op 2026-10-22 op basis van de Hive Workshop-pagina
> [Tower Survivors](https://www.hiveworkshop.com/threads/tower-survivors.353429/) (auteur Nethalythic, versie 1.92, 8 spelers).
> Er is **geen mapbestand** gedownload of uitgelezen. Alles hieronder komt uit de beschrijving en de changelog op die pagina.
> De waarden in onze modus zijn **eigen ontwerp** (`docs/design/laatste-toren.md`); namen, getallen en teksten van die map zijn niet overgenomen.

## Wat Tower Survivors is (volgens de pagina)

- **Roguelike tower defense** in de geest van *Vampire Survivors* en *Halls of Torment*. De speler **kan niet bewegen en niets in de wereld
  aanwijzen**: je kiest alleen wapens en verbeteringen voor je **ene toren** en balanceert inkomen, schade en overleving.
- **Vijanden komen op de toren af en vallen hem aan.** Ze worden sterker in de tijd, met extra schaling na 10 en 15 minuten.
- **Winkel:** wapens en verbeteringen, met **herladen** ("reroll"), een Clear-knop (alles weg zonder beloning, herstel en 1 s onkwetsbaar) en "bad luck
  protection" voor inkomen-upgrades.
- **Zeldzaamheden:** gewoon, ongewoon, zeldzaam, episch (prijzen 500 tot 10.000 goud).
- **Ongeveer 90 wapens** met schadetypes (normaal, doordringend, magie, beleg, chaos). Voorbeelden: een sikkel die uitdraait en geneest, een tesla-kanon dat
  kaatst, een mijnenlegger, een katapult, een aura.
- **Upgrades** in vier groepen (inkomen, schade, overleving, hulp): kritieke treffers, pantser, blokkeren, **doornen** (aanvallers krijgen schade terug),
  goudbonussen, een schild, een herrijzenis (Phoenix, Ankh).
- **Goudwagens:** snelle vijanden die 100 goud waard zijn. **Eindbazen** met veel schade.
- **Modi:** multiplayer (tot 8, de eerste helft die sterft verliest) en **Solo** (direct beginnen, andere schaling na 15 minuten).
- **Niet op de pagina:** de volledige wapenlijst, de golfsamenstelling en de exacte formules.

## Wat we overnemen (de ideeën) en wat niet

| Idee | Onze versie |
|---|---|
| Eén toren die niet beweegt | Eén toren in het midden van een ronde arena, vaste camera met inzoomen |
| Wapens en verbeteringen kopen | Winkel met 5 kaarten, elke 45 s ververst, herladen kost steeds meer, 20 wapens en 22 verbeteringen met eigen namen |
| Zeldzaamheden | Gewoon, ongewoon, zeldzaam, episch; de kansen verschuiven in de tijd |
| Schadetypes | Alleen **fysiek** (pantser telt) en **magisch** (negeert pantser) |
| Doornen, pantser, blokkeren, schild, Phoenix/Ankh | Allemaal, met eigen waarden |
| Clear-knop | "Wegvegen": alles behalve eindbazen weg, 25% genezing, 1 s veilig, 2 minuten rust |
| Goudwagens | **Goudstieren**: snel, lopen langs de toren en verdwijnen als je ze niet raakt |
| Solo-modus, 15 minuten | Win door 15 minuten te overleven; moeilijkheid = sterkte van de vijanden |
| Multiplayer met 8 spelers, skins, challenges, prestige | Niet overgenomen |

## Bronnen

- [Tower Survivors (v1.92)](https://www.hiveworkshop.com/threads/tower-survivors.353429/), Hive Workshop
