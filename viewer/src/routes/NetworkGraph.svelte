<script>
  import { onMount } from 'svelte';

  export let data;
  
  /**
	 * @type {HTMLElement}
	 */
  let container;

  onMount(async () => {
    // Dynamically import vis-network only on the client side
    const { Network } = await import('vis-network');

    const options = {}; // Add your network options here

    const network = new Network(container, data, options);
  });
</script>

<div bind:this={container} style="width: 100vw; height: 100vh;"></div>