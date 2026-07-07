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
            "{{ colors.on_surface.light.hex }}",
            "{{ colors.on_surface.light.hex | saturate: 70.0, hsl }}",
            "{{ colors.secondary.light.hex | saturate: 20.0, hsl }}",
            "{{ colors.tertiary.light.hex | saturate: 15.0, hsl }}",
            "{{ colors.primary.light.hex }}",
            "{{ colors.tertiary.light.hex }}",
            "{{ colors.on_secondary_container.light.hex | saturate: 20.0, hsl }}",
            "{{ colors.on_surface_variant.light.hex }}"
        },
        brights = {
            "{{ colors.on_surface.light.hex }}",
            "{{ colors.surface_tint.light.hex | saturate: 15.0, hsl }}",
            "{{ colors.secondary.light.hex | saturate: 20.0, hsl }}",
            "{{ colors.tertiary.light.hex | saturate: 15.0, hsl }}",
            "{{ colors.primary.light.hex }}",
            "{{ colors.tertiary.light.hex }}",
            "{{ colors.on_primary_container.light.hex | saturate: 10.0, hsl }}",
            "{{ colors.on_surface.light.hex }}"
        }
    }
}