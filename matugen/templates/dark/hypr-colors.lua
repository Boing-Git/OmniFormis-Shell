return {
    image = "{{image}}",
    mode = "dark",
<* for name, value in colors *>
    {{name}} = "0xff{{value.dark.hex_stripped}}",
<* endfor *>
}