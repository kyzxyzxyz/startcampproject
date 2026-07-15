<template>
  <button
    :type="type"
    :class="classes"
    :disabled="disabled"
    @click="$emit('click')"
  >
    <slot />
  </button>
</template>

<script>
export default {
  name: 'BaseButton',
  props: {
    variant: { type: String, default: 'primary' }, // primary / ghost / neutral
    size: { type: String, default: 'md' }, // sm / md / lg
    type: { type: String, default: 'button' },
    disabled: { type: Boolean, default: false }
  },
  computed: {
    classes() {
      return [
        'base-btn',
        `base-btn--${this.variant}`,
        `base-btn--${this.size}`,
        { 'base-btn--disabled': this.disabled }
      ]
    }
  }
}
</script>

<style scoped>
.base-btn {
  font-family: inherit;
  font-weight: 700;
  border-radius: 10px;
  padding: 8px 12px;
  border: none;
  cursor: pointer;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  gap: 8px;
  box-sizing: border-box;
  transition: all .12s ease;
  min-height: 36px;
  min-width: 76px;
  font-size: 14px;
}
.base-btn--sm { padding:6px 8px; min-height:32px; min-width:64px; font-size:13px; border-radius:8px; }
.base-btn--lg { padding:10px 14px; font-size:15px; min-height:40px; }

.base-btn--primary { background: var(--primary); color: #fff; box-shadow: 0 8px 24px rgba(37,99,235,0.12); }
.base-btn--ghost { background: transparent; color: var(--primary); border: 1px solid rgba(11,17,34,0.06); box-shadow:none; }
.base-btn--neutral { background: #f3f4f6; color: #0b1220; border: 1px solid rgba(11,17,34,0.04); }

.base-btn:active { transform: translateY(1px); }
.base-btn--disabled { opacity: 0.55; cursor: default; pointer-events: none; }
</style>