return {
    image = "{{image}}",
    mode = "light",
<* for name, value in colors *>
    {{name}} = "0xff{{value.light.hex_stripped}}",
<* endfor *>
}