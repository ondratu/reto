/**
 * Tells the latest of several asynchronous requests from the obsolete ones.
 * Take a ticket with {@link next} when a request starts and check it with
 * {@link is_current} when the result arrives.
 */
public class Reto.Generation {
    private uint value = 0;

    public uint next () {
        return ++value;
    }

    /**
     * Makes every ticket taken so far obsolete.
     */
    public void invalidate () {
        value++;
    }

    public bool is_current (uint ticket) {
        return ticket == value;
    }
}
