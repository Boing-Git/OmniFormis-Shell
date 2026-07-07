return {
    colors = {
        background = "{{colors.background.light.hex}}",
        foreground = "{{colors.on_surface.light.hex}}",
        cursor_bg = "{{colors.on_surface.light.hex}}",
        cursor_border = "{{colors.on_surface.light.hex}}",
        cursor_fg = "{{colors.on_surface_variant.light.hex}}",
        selection_bg = "{{colors.secondary_fixed_dim.light.hex}}",
        selection_fg = "{{colors.on_secondary.light.hex}}",
        split = "{{colors.secondary_fixed_dim.light.hex}}",
        ansi = {
            "{{ colors.surface_dim.light.hex }}",
            "{{ colors.on_surface.light.hex | saturate: 70.0, hsl }}",
            "{{ colors.secondary.light.hex | saturate: 20.0, hsl }}",
            "{{ colors.tertiary.light.hex | saturate: 15.0, hsl }}",
            "{{ colors.primary.light.hex }}",
            "{{ colors.tertiary.light.hex }}",
            "{{ colors.secondary_container.light.hex | saturate: 20.0, hsl }}",
            "{{ colors.on_surface_variant.light.hex }}"
        },
        brights = {
            "{{ colors.surface_variant.light.hex }}",
            "{{ colors.surface_tint.light.hex | saturate: 15.0, hsl }}",
            "{{ colors.secondary.light.hex | auto_lightness: 10.0 | saturate: 20.0, hsl }}",
            "{{ colors.tertiary.light.hex | auto_lightness: 10.0 | saturate: 15.0, hsl }}",
            "{{ colors.primary.light.hex | auto_lightness: 10.0 }}",
            "{{ colors.tertiary.light.hex | auto_lightness: 10.0 }}",
            "{{ colors.primary_container.light.hex | saturate: 10.0, hsl }}",
            "{{ colors.on_surface.light.hex }}"
        }
    }
}