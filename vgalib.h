
class VGAOutput {
  public:
    void begin();
    void fill(char);
    void line(int, int, int, int, char);
    void setPixel(int, int, char);
    void flip();
    void blit(int, int, int, int, const char *);
};
