return {
    image = "{{image}}",
<* for name, value in colors *>
    {{name}} = "0xff{{value.light.hex_stripped}}",
<* endfor *>
}