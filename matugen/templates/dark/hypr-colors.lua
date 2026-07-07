return {
    image = "{{image}}",
<* for name, value in colors *>
    {{name}} = "0xff{{value.dark.hex_stripped}}",
<* endfor *>
}